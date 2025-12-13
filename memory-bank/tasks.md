# Memory Bank: Tasks

## Current Task
Fix 4 bugs in commands subdirectory implementation:
1. Subdirectory rules don't show up in mode list
2. Commands not copied recursively (only top-level)
3. List doesn't show tree for rulesets without commands
4. List doesn't show .mdc files in rulesets

## Status
- [x] Task definition
- [x] Complexity determination
- [x] Implementation plan
- [x] Phase 0: Regression tests written (should fail)
- [ ] Phase 1: Fix Bug 2 (recursive commands)
- [ ] Phase 2: Fix Bug 4 (show .mdc files)
- [ ] Phase 3: Verify all tests pass

## Requirements

### Bug Descriptions

**Bug 1: Subdirectory rules don't show up in mode list**
- **Issue**: Rules in subdirectories (e.g., `supporting/piracy.mdc`) are copied but don't appear in `ai-rizz list` output
- **Root Cause Analysis**: 
  - Files ARE being copied (we see `piracy.mdc` in `.cursor/rules/shared`)
  - The list command shows rulesets, not individual files from rulesets
  - The tree display should show `.mdc` files in subdirectories, but Bug 4 prevents this
  - After fixing Bug 4, subdirectory `.mdc` files should appear in the tree
- **Impact**: Users can't see which rules from subdirectories are installed
- **Fix**: This will be resolved by fixing Bug 4 (showing `.mdc` files in tree)

**Bug 2: Commands not copied recursively**
- **Issue**: Only top-level files in `commands/` directory are copied. Nested files (e.g., `commands/subs/eat.md`) are not copied.
- **Root Cause**: `copy_ruleset_commands()` uses `find ... -maxdepth 1` which only gets files at the first level
- **Impact**: Commands in subdirectories are not available

**Bug 3: List doesn't show tree for rulesets without commands**
- **Issue**: Only `temp-test` (which has commands) shows a tree structure. Other rulesets like `shell`, `meta`, `niko` don't show their contents.
- **Root Cause**: The tree command's ignore pattern excludes all files, but the logic might only be applied when commands exist, or the pattern is too aggressive
- **Impact**: Users can't see what's in rulesets without commands

**Bug 4: List doesn't show .mdc files in rulesets**
- **Issue**: The `temp-test` ruleset shows directories (`commands`, `supporting`) but not the actual `.mdc` files like `temp-test.mdc` or `supporting/piracy.mdc`
- **Root Cause**: The ignore pattern `find . -name 'commands' -type d -prune -o -type f,l -printf '%f|'` excludes ALL files, including `.mdc` files. The pattern should only exclude non-`.mdc` files.
- **Impact**: Users can't see which rules are in a ruleset

## Complexity Level
**Level 2: Simple Enhancement** (Bug Fixes)

### Complexity Analysis
- **Scope**: Multiple bug fixes in existing functionality
- **Design Decisions**: Minimal (fixing incorrect logic)
- **Risk**: Low (targeted fixes to specific bugs)
- **Implementation Effort**: Low (hours to 1 day)
- **Components Affected**:
  - `copy_entry_to_target()` - Fix recursive .mdc file copying
  - `copy_ruleset_commands()` - Fix recursive command copying
  - `cmd_list()` - Fix tree display logic and ignore pattern

## Implementation Plan

### Phase 1: Fix Bug 2 - Recursive Command Copying
**Location**: `copy_ruleset_commands()` function (line ~3259)
**Issue**: `-maxdepth 1` limits to top-level only
**Fix**: Remove `-maxdepth 1` and copy all files recursively, preserving directory structure
**Implementation**:
- **Current code** (line 3259):
  ```bash
  find "${crc_source_commands_dir}" -mindepth 1 -maxdepth 1 \( -type f -o -type l \) > "${crc_temp_file}"
  ```
- **New code**:
  ```bash
  find "${crc_source_commands_dir}" -mindepth 1 \( -type f -o -type l \) > "${crc_temp_file}"
  ```
- **Copy logic change**: Preserve relative path structure when copying:
  - **Current** (line ~3267): `cp -L "${crc_source_file}" "${crc_target_commands_dir}/"`
  - **New**: Calculate relative path and create target directory structure
  ```bash
  while IFS= read -r crc_source_file; do
      if [ -n "${crc_source_file}" ] && ([ -f "${crc_source_file}" ] || [ -L "${crc_source_file}" ]); then
          # Calculate relative path from commands directory
          crc_rel_path="${crc_source_file#${crc_source_commands_dir}/}"
          crc_target_file="${crc_target_commands_dir}/${crc_rel_path}"
          
          # Create target directory structure if needed
          mkdir -p "$(dirname "${crc_target_file}")" || {
              warn "Failed to create directory for: ${crc_rel_path}"
              continue
          }
          
          # Copy file following symlinks
          if ! cp -L "${crc_source_file}" "${crc_target_file}"; then
              warn "Failed to copy command file: ${crc_rel_path}"
          fi
      fi
  done < "${crc_temp_file}"
  ```
- **Result**: `commands/subs/eat.md` → `.cursor/commands/subs/eat.md` (preserves structure)

### Phase 2: Fix Bug 1 - Subdirectory Rules Display
**Location**: `cmd_list()` function (resolved by Bug 4 fix)
**Issue**: Rules in subdirectories don't appear in list tree
**Root Cause**: Bug 4 prevents `.mdc` files from showing in tree, which includes subdirectory files
**Fix**: This will be automatically resolved when Bug 4 is fixed (tree will show all `.mdc` files including those in subdirectories)
**Note**: Files are already being copied correctly (flattened structure is intentional). The issue is only in display.

### Phase 3: Fix Bug 4 - List Shows .mdc Files
**Location**: `cmd_list()` function (line ~2566)
**Issue**: Ignore pattern excludes ALL files including `.mdc` files
**Current Pattern**: `find . -name 'commands' -type d -prune -o -type f,l -printf '%f|'`
**Problem**: This excludes all files (including `.mdc`), but we want to show `.mdc` files and directories
**Fix**: Modify pattern to exclude only non-`.mdc` files
**Implementation**:
- **Current code** (line 2566):
  ```bash
  cl_ignore_pattern=$(cd "${cl_ruleset}" && find . -name 'commands' -type d -prune -o -type f,l -printf '%f|' | head -c -1)
  ```
- **New code**:
  ```bash
  cl_ignore_pattern=$(cd "${cl_ruleset}" && find . -name 'commands' -type d -prune -o \( -type f -o -type l \) ! -name '*.mdc' -printf '%f|' | head -c -1)
  ```
- **Logic Explanation**:
  - `-name 'commands' -type d -prune`: Don't traverse into `commands/` directory (we expand it separately with `-L 2`)
  - `-o \( -type f -o -type l \) ! -name '*.mdc'`: For all other files/links, exclude those that are NOT `.mdc` files
  - Result: Tree shows all directories + all `.mdc` files (at any depth) + expands `commands/` directory to level 2
- **Testing**: 
  - Verify `.mdc` files at root level appear
  - Verify `.mdc` files in subdirectories appear (e.g., `supporting/piracy.mdc`)
  - Verify non-`.mdc` files are excluded (except in `commands/` which is expanded separately)

### Phase 4: Fix Bug 3 - List Shows Tree for All Rulesets
**Location**: `cmd_list()` function (line ~2560)
**Issue**: Tree display only works for rulesets with commands or subdirectories
**Root Cause Analysis**: 
- The tree command IS being called for all rulesets (code shows it's in the loop)
- The ignore pattern is excluding everything for rulesets that only have `.mdc` files
- After fixing Bug 4, this should automatically work (tree will show `.mdc` files)
**Fix**: After fixing Bug 4, verify tree shows for all rulesets. If not, may need to adjust tree command or ensure it always runs.

### Phase 0: Write Regression Tests (TDD Step 1-3) ✓
**Status**: Complete and Verified
**Location**: `tests/unit/test_ruleset_bug_fixes.test.sh` (created)
**Purpose**: Write tests that will FAIL with current implementation, then PASS after fixes
**Test File**: `tests/unit/test_ruleset_bug_fixes.test.sh` (created with 5 test cases)
**Verification Results**:
- All 5 tests FAIL as expected (10 total failures)
- `test_commands_copied_recursively()`: FAILS ✓ (nested commands not copied)
- `test_subdirectory_rules_visible_in_list()`: FAILS ✓ (subdirectory rules not shown)
- `test_list_shows_tree_for_all_rulesets()`: FAILS ✓ (tree not shown for simple rulesets)
- `test_mdc_files_visible_in_list()`: FAILS ✓ (.mdc files not shown)
- `test_complex_ruleset_display()`: FAILS ✓ (multiple issues)
- **Ready for Phase 1**: Tests confirmed to fail, can proceed with fixes

#### Test Structure
Following TDD workflow:
1. **Stub tests** - Create empty test functions with descriptions
2. **Implement tests** - Fill out test logic (should fail)
3. **Run tests** - Verify they fail as expected
4. **Fix bugs** - Implement fixes
5. **Re-run tests** - Verify they pass

#### Test Cases

**Test 1: Bug 2 - Recursive Command Copying**
```bash
test_commands_copied_recursively() {
	# Setup: Create ruleset with nested commands structure
	mkdir -p "$REPO_DIR/rulesets/test-recursive/commands/subdir"
	echo "nested command" > "$REPO_DIR/rulesets/test-recursive/commands/subdir/nested.md"
	echo "top command" > "$REPO_DIR/rulesets/test-recursive/commands/top.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-recursive/rule1.mdc"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit >/dev/null 2>&1
	
	# Action: Add ruleset
	cmd_add_ruleset "test-recursive" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Both top-level and nested commands copied
	test -f "commands/top.md" || fail "Top-level command should be copied"
	test -f "commands/subdir/nested.md" || fail "Nested command should be copied recursively"
	# CURRENTLY FAILS: nested.md not copied (only top-level copied)
}
```

**Test 2: Bug 1 - Subdirectory Rules Visible in List**
```bash
test_subdirectory_rules_visible_in_list() {
	# Setup: Create ruleset with rules in subdirectory
	mkdir -p "$REPO_DIR/rulesets/test-subdir/supporting"
	echo "subdir rule" > "$REPO_DIR/rulesets/test-subdir/supporting/subrule.mdc"
	echo "root rule" > "$REPO_DIR/rulesets/test-subdir/rootrule.mdc"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit >/dev/null 2>&1
	
	# Action: Add ruleset and list
	cmd_add_ruleset "test-subdir" --commit >/dev/null 2>&1
	output=$(cmd_list)
	
	# Expected: Both rules visible in list tree
	echo "$output" | grep -q "rootrule.mdc" || fail "Root rule should appear in list"
	echo "$output" | grep -q "subrule.mdc" || fail "Subdirectory rule should appear in list"
	echo "$output" | grep -q "supporting" || fail "Supporting directory should appear in list"
	# CURRENTLY FAILS: subrule.mdc not shown (ignore pattern excludes .mdc files)
}
```

**Test 3: Bug 3 - Tree Shows for All Rulesets**
```bash
test_list_shows_tree_for_all_rulesets() {
	# Setup: Create ruleset with only .mdc files (no commands, no subdirs)
	mkdir -p "$REPO_DIR/rulesets/test-simple"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-simple/rule1.mdc"
	ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/test-simple/rule2.mdc"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit >/dev/null 2>&1
	
	# Action: Add ruleset and list
	cmd_add_ruleset "test-simple" --commit >/dev/null 2>&1
	output=$(cmd_list)
	
	# Expected: Ruleset shows tree with .mdc files
	echo "$output" | grep -A 5 "test-simple" | grep -q "rule1.mdc" || fail "rule1.mdc should appear in tree"
	echo "$output" | grep -A 5 "test-simple" | grep -q "rule2.mdc" || fail "rule2.mdc should appear in tree"
	# CURRENTLY FAILS: No tree shown (ignore pattern excludes everything)
}
```

**Test 4: Bug 4 - .mdc Files Visible in List**
```bash
test_mdc_files_visible_in_list() {
	# Setup: Create ruleset with .mdc files and other files
	mkdir -p "$REPO_DIR/rulesets/test-mdc"
	echo "rule content" > "$REPO_DIR/rulesets/test-mdc/rule.mdc"
	echo "readme content" > "$REPO_DIR/rulesets/test-mdc/README.md"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit >/dev/null 2>&1
	
	# Action: Add ruleset and list
	cmd_add_ruleset "test-mdc" --commit >/dev/null 2>&1
	output=$(cmd_list)
	
	# Expected: .mdc file visible, README.md excluded
	echo "$output" | grep -A 5 "test-mdc" | grep -q "rule.mdc" || fail ".mdc file should appear in tree"
	echo "$output" | grep -A 5 "test-mdc" | grep -q "README.md" && fail "README.md should NOT appear (not .mdc)"
	# CURRENTLY FAILS: rule.mdc not shown (ignore pattern excludes all files)
}
```

**Test 5: Combined Test - Ruleset with Commands, Subdirs, and .mdc Files**
```bash
test_complex_ruleset_display() {
	# Setup: Create ruleset matching temp-test structure
	mkdir -p "$REPO_DIR/rulesets/test-complex/commands/subs"
	mkdir -p "$REPO_DIR/rulesets/test-complex/supporting"
	echo "command" > "$REPO_DIR/rulesets/test-complex/commands/top.md"
	echo "nested" > "$REPO_DIR/rulesets/test-complex/commands/subs/nested.md"
	echo "rule" > "$REPO_DIR/rulesets/test-complex/test-complex.mdc"
	echo "subrule" > "$REPO_DIR/rulesets/test-complex/supporting/subrule.mdc"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit >/dev/null 2>&1
	
	# Action: Add ruleset and list
	cmd_add_ruleset "test-complex" --commit >/dev/null 2>&1
	output=$(cmd_list)
	
	# Expected: All components visible
	echo "$output" | grep -A 10 "test-complex" | grep -q "commands" || fail "commands/ should appear"
	echo "$output" | grep -A 10 "test-complex" | grep -q "test-complex.mdc" || fail "Root .mdc should appear"
	echo "$output" | grep -A 10 "test-complex" | grep -q "supporting" || fail "supporting/ should appear"
	echo "$output" | grep -A 10 "test-complex" | grep -q "subrule.mdc" || fail "Subdirectory .mdc should appear"
	
	# Verify commands copied
	test -f "commands/top.md" || fail "Top command should be copied"
	test -f "commands/subs/nested.md" || fail "Nested command should be copied"
	# CURRENTLY FAILS: Multiple issues (commands not recursive, .mdc files not shown)
}
```

### Implementation Order (TDD Workflow)

#### Phase 0: Write Regression Tests (TDD Step 1-3) ✓
**Status**: Complete
**Test File**: `tests/unit/test_ruleset_bug_fixes.test.sh`
**Test Cases**:
1. `test_commands_copied_recursively()` - Tests Bug 2
2. `test_subdirectory_rules_visible_in_list()` - Tests Bug 1
3. `test_list_shows_tree_for_all_rulesets()` - Tests Bug 3
4. `test_mdc_files_visible_in_list()` - Tests Bug 4
5. `test_complex_ruleset_display()` - Tests all bugs together

**Expected Result**: All 5 tests should FAIL with current implementation
**Verification**: Run tests to confirm they fail as expected

#### Phase 1: Fix Bug 2 (Recursive Commands)
**After Phase 0**: Tests 1 and 5 should still fail
**Implementation**:
- Remove `-maxdepth 1` from find command in `copy_ruleset_commands()`
- Preserve directory structure when copying (calculate relative paths)
- Update copy logic to create target directory structure

**Expected Result**: Tests 1 and 5 (command copying parts) should PASS
**Verification**: Run `test_commands_copied_recursively()` and verify nested commands copied

#### Phase 2: Fix Bug 4 (Show .mdc Files)
**After Phase 1**: Tests 2, 3, 4, and parts of 5 should still fail
**Implementation**:
- Modify ignore pattern in `cmd_list()` to exclude only non-`.mdc` files
- Change: `find . -name 'commands' -type d -prune -o -type f,l -printf '%f|'`
- To: `find . -name 'commands' -type d -prune -o \( -type f -o -type l \) ! -name '*.mdc' -printf '%f|'`

**Expected Result**: All tests should PASS (Bug 1 and Bug 3 auto-fixed)
**Verification**: Run all 5 tests, all should pass

#### Phase 3: Verify All Tests Pass
**After Phase 2**: All regression tests should pass
**Actions**:
- Run full test suite: `make test`
- Verify no regressions in existing tests
- Update documentation if behavior changes significantly

## Dependencies and Challenges

### Dependencies
- Existing ruleset handling infrastructure
- Tree command availability (with fallback)

### Challenges
- **Bug 1**: Need to understand if flattening is intentional or a bug
- **Bug 4**: Ignore pattern logic needs careful testing to ensure it doesn't break existing behavior
- **Backward Compatibility**: Ensure fixes don't break existing ruleset displays

## Success Criteria
- [ ] Commands in subdirectories are copied recursively (e.g., `commands/subs/eat.md` → `.cursor/commands/subs/eat.md`)
- [ ] Rules in subdirectories are visible in list output (e.g., `supporting/piracy.mdc` appears in tree)
- [ ] All rulesets show tree structure in list (not just those with commands)
- [ ] All `.mdc` files in rulesets are visible in list output (root level and subdirectories)
- [ ] Existing behavior preserved (no regressions)
- [ ] All tests pass

## Test Strategy

### New Test Cases Needed
1. **Recursive command copying**:
   - Create ruleset with `commands/subdir/file.md`
   - Verify file is copied to `.cursor/commands/subdir/file.md`
   
2. **Subdirectory rules in list**:
   - Create ruleset with `subdir/rule.mdc`
   - Verify rule appears in list tree under `subdir/`
   
3. **Tree for all rulesets**:
   - Verify rulesets without commands show tree
   - Verify rulesets with only `.mdc` files show tree
   
4. **`.mdc` files in tree**:
   - Verify all `.mdc` files appear in tree (root and subdirectories)
   - Verify non-`.mdc` files are excluded (except in `commands/`)

### Existing Tests
- Verify all existing tests still pass
- Update list display tests if needed to reflect new behavior
