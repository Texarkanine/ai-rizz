# Implementation Phase 1: Unit Test Development

## Overview

This document provides a detailed step-by-step plan for implementing comprehensive unit tests for the ai-rizz progressive initialization design. These tests will define the contract for the new system and are expected to have some failures against the current implementation, which validates that we're testing meaningful behavioral changes.

**Important**: These tests document the target design behavior and will intentionally fail against the current single-mode system. This is expected and validates our test completeness.

## Current Testing Infrastructure Analysis

### Existing Test Structure
- **Test Framework**: shunit2 
- **Test Location**: `tests/unit/`
- **Common Utilities**: `tests/common.sh` provides:
  - Test environment setup/teardown with temp directories
  - Mock git operations
  - Manifest manipulation utilities  
  - File existence assertions
  - Script sourcing with `source_ai_rizz()`

### Current Test Files
- `sync_shunit.test.sh` - Tests sync command and cleanup behavior
- `manifest_shunit.test.sh` - Tests manifest file operations

### Testing Patterns Established
1. Each test file sources `tests/common.sh`
2. Uses `source_ai_rizz()` to load the actual ai-rizz script
3. `setUp()` creates temp directory with mock repo structure
4. Tests use real file operations in temp directories
5. Tests verify actual command behavior, not just internal functions

## Phase 1 Implementation Plan

### Step 1: Test Infrastructure Updates

**Files to Modify**: `tests/common.sh`

#### 1.1 Extend Common Test Utilities

Add support for dual-mode testing:

```bash
# New manifest file constants
COMMIT_MANIFEST_FILE="ai-rizz.inf"
LOCAL_MANIFEST_FILE="ai-rizz.local.inf"

# New directory constants  
SHARED_DIR="shared"
LOCAL_DIR="local"

# New glyph constants for testing
COMMITTED_GLYPH="●"
LOCAL_GLYPH="◐"
UNINSTALLED_GLYPH="○"

# Mode detection utilities
assert_local_mode_exists() {
    assertTrue "Local manifest should exist" "[ -f '$LOCAL_MANIFEST_FILE' ]"
    assertTrue "Local directory should exist" "[ -d '$TARGET_DIR/$LOCAL_DIR' ]"
}

assert_commit_mode_exists() {
    assertTrue "Commit manifest should exist" "[ -f '$COMMIT_MANIFEST_FILE' ]"  
    assertTrue "Commit directory should exist" "[ -d '$TARGET_DIR/$SHARED_DIR' ]"
}

assert_no_modes_exist() {
    assertFalse "Local manifest should not exist" "[ -f '$LOCAL_MANIFEST_FILE' ]"
    assertFalse "Commit manifest should not exist" "[ -f '$COMMIT_MANIFEST_FILE' ]"
}

# Git exclude testing utilities
assert_git_exclude_contains() {
    assertTrue "Git exclude should contain $1" "grep -q '^$1$' .git/info/exclude"
}

assert_git_exclude_not_contains() {
    assertFalse "Git exclude should not contain $1" "grep -q '^$1$' .git/info/exclude"
}

# Legacy repository setup for migration testing
setup_legacy_local_repo() {
    # Create old-style local mode setup
    echo "$SOURCE_REPO	$TARGET_DIR" > "$COMMIT_MANIFEST_FILE"
    echo "rules/rule1.mdc" >> "$COMMIT_MANIFEST_FILE"
    mkdir -p "$TARGET_DIR/$SHARED_DIR"
    cp "$REPO_DIR/rules/rule1.mdc" "$TARGET_DIR/$SHARED_DIR/"
    
    # Add to git exclude to simulate legacy local mode
    mkdir -p .git/info
    echo "$COMMIT_MANIFEST_FILE" > .git/info/exclude
    echo "$TARGET_DIR/$SHARED_DIR" >> .git/info/exclude
}

setup_legacy_commit_repo() {
    # Create old-style commit mode setup  
    echo "$SOURCE_REPO	$TARGET_DIR" > "$COMMIT_MANIFEST_FILE"
    echo "rules/rule1.mdc" >> "$COMMIT_MANIFEST_FILE"
    mkdir -p "$TARGET_DIR/$SHARED_DIR"
    cp "$REPO_DIR/rules/rule1.mdc" "$TARGET_DIR/$SHARED_DIR/"
    
    # No git exclude entries = commit mode
}
```

#### 1.2 Enhanced setUp for Git Environment

Update `setUp()` to create proper git repository structure:

```bash
setUp() {
    # ... existing setup ...
    
    # Initialize current directory as git repo for testing
    git init . >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1
    
    # Create initial git structure
    mkdir -p .git/info
    touch .git/info/exclude
}
```

### Step 2: Progressive Initialization Tests  

**File**: `tests/unit/test_progressive_init.sh`

#### 2.1 Single-Mode Initialization Tests

```bash
test_init_local_mode_only() {
    # Test: ai-rizz init $REPO --local
    # Expected: Creates local manifest and directory only
    
    cmd_init "$SOURCE_REPO" --local
    
    assert_local_mode_exists
    assert_file_not_exists "$COMMIT_MANIFEST_FILE"
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TARGET_DIR/$LOCAL_DIR"
}

test_init_commit_mode_only() {
    # Test: ai-rizz init $REPO --commit  
    # Expected: Creates commit manifest and directory only
    
    cmd_init "$SOURCE_REPO" --commit
    
    assert_commit_mode_exists
    assert_file_not_exists "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$COMMIT_MANIFEST_FILE"
}

test_init_requires_mode_flag() {
    # Test: ai-rizz init $REPO (no mode flag)
    # Expected: Error or prompt (current design shows prompt)
    
    # This test may need to mock stdin for interactive prompt
    # or verify error message for non-interactive mode
}

test_init_custom_target_dir() {
    # Test: ai-rizz init $REPO -d .custom/rules --local
    # Expected: Uses custom target directory
    
    custom_dir=".custom/rules"
    cmd_init "$SOURCE_REPO" -d "$custom_dir" --local
    
    assertTrue "Custom directory should exist" "[ -d '$custom_dir/$LOCAL_DIR' ]"
    assert_git_exclude_contains "$custom_dir/$LOCAL_DIR"
}
```

#### 2.2 Manifest Header Validation Tests

```bash
test_init_creates_correct_manifest_headers() {
    # Test both modes create proper headers
    
    cmd_init "$SOURCE_REPO" --local
    first_line=$(head -n1 "$LOCAL_MANIFEST_FILE")
    assertEquals "Local manifest header incorrect" "$SOURCE_REPO	$TARGET_DIR" "$first_line"
    
    cmd_init "$SOURCE_REPO" --commit  
    first_line=$(head -n1 "$COMMIT_MANIFEST_FILE")
    assertEquals "Commit manifest header incorrect" "$SOURCE_REPO	$TARGET_DIR" "$first_line"
}
```

### Step 3: Lazy Initialization Tests

**File**: `tests/unit/test_lazy_initialization.sh`

#### 3.1 Auto-Mode Creation Tests

```bash
test_lazy_init_local_from_commit() {
    # Setup: Only commit mode exists
    cmd_init "$SOURCE_REPO" --commit
    assert_commit_mode_exists
    assert_file_not_exists "$LOCAL_MANIFEST_FILE"
    
    # Test: Add rule to local mode (should auto-create local mode)
    cmd_add_rule "rule1.mdc" --local
    
    # Expected: Local mode created, rule added to local
    assert_local_mode_exists
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    
    # Verify local manifest has correct header copied from commit manifest
    local_header=$(head -n1 "$LOCAL_MANIFEST_FILE")
    commit_header=$(head -n1 "$COMMIT_MANIFEST_FILE") 
    assertEquals "Headers should match" "$commit_header" "$local_header"
}

test_lazy_init_commit_from_local() {
    # Setup: Only local mode exists
    cmd_init "$SOURCE_REPO" --local
    assert_local_mode_exists
    assert_file_not_exists "$COMMIT_MANIFEST_FILE"
    
    # Test: Add rule to commit mode (should auto-create commit mode)
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Commit mode created, rule added to commit
    assert_commit_mode_exists
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
}

test_lazy_init_preserves_existing_rules() {
    # Setup: Local mode with existing rule
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule2.mdc" --local
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    
    # Test: Add rule to commit mode
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Both rules exist in their respective modes
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
}

test_lazy_init_no_mode_error() {
    # Setup: No modes exist
    assert_no_modes_exist
    
    # Test: Add rule without init
    output=$(cmd_add_rule "rule1.mdc" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Error message about running init first
    echo "$output" | grep -q "please run.*init" || fail "Should suggest running init"
}
```

#### 3.2 Ruleset Lazy Initialization Tests

```bash
test_lazy_init_with_rulesets() {
    # Setup: Commit mode only
    cmd_init "$SOURCE_REPO" --commit
    
    # Test: Add ruleset to local mode
    cmd_add_ruleset "ruleset1" --local
    
    # Expected: Local mode created, all ruleset rules copied to local
    assert_local_mode_exists
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
}
```

### Step 4: Mode Detection and Smart Defaults Tests

**File**: `tests/unit/test_mode_detection.sh`

#### 4.1 Mode Detection Logic Tests

```bash
test_detect_local_mode_only() {
    # Setup: Local mode only
    cmd_init "$SOURCE_REPO" --local
    
    # Test internal mode detection functions
    # These test the new utility functions that will be added
    assertTrue "Should detect local mode" "has_local_mode"
    assertFalse "Should not detect commit mode" "has_commit_mode"
}

test_detect_commit_mode_only() {
    # Setup: Commit mode only  
    cmd_init "$SOURCE_REPO" --commit
    
    assertTrue "Should detect commit mode" "has_commit_mode"
    assertFalse "Should not detect local mode" "has_local_mode"
}

test_detect_dual_mode() {
    # Setup: Both modes via lazy init
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit  # Triggers lazy init
    
    assertTrue "Should detect local mode" "has_local_mode"
    assertTrue "Should detect commit mode" "has_commit_mode"
}
```

#### 4.2 Smart Mode Selection Tests

```bash
test_add_rule_single_mode_auto_select() {
    # Setup: Local mode only
    cmd_init "$SOURCE_REPO" --local
    
    # Test: Add rule without mode flag
    cmd_add_rule "rule1.mdc"
    
    # Expected: Automatically uses local mode
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
}

test_add_rule_dual_mode_requires_flag() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit  # Creates dual mode
    
    # Test: Add rule without mode flag
    output=$(cmd_add_rule "rule2.mdc" 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Error requiring mode specification
    echo "$output" | grep -q "mode" || fail "Should require mode specification"
}
```

### Step 5: Mode Migration and Conflict Resolution Tests

**File**: `tests/unit/test_conflict_resolution.sh`

#### 5.1 Rule Mode Migration Tests

```bash
test_migrate_rule_local_to_commit() {
    # Setup: Rule in local mode
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    
    # Test: Add same rule to commit mode
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Rule moved from local to commit
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    
    # Verify manifests updated
    local_content=$(cat "$LOCAL_MANIFEST_FILE")
    echo "$local_content" | grep -q "rule1.mdc" && fail "Rule should be removed from local manifest"
    
    commit_content=$(cat "$COMMIT_MANIFEST_FILE")
    echo "$commit_content" | grep -q "rule1.mdc" || fail "Rule should be in commit manifest"
}

test_migrate_rule_commit_to_local() {
    # Setup: Rule in commit mode
    cmd_init "$SOURCE_REPO" --commit
    cmd_add_rule "rule1.mdc" --commit
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    
    # Test: Add same rule to local mode
    cmd_add_rule "rule1.mdc" --local
    
    # Expected: Rule moved from commit to local
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
}

test_migrate_ruleset_with_all_rules() {
    # Setup: Ruleset in local mode
    cmd_init "$SOURCE_REPO" --local
    cmd_add_ruleset "ruleset1" --local
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    
    # Test: Add same ruleset to commit mode
    cmd_add_ruleset "ruleset1" --commit
    
    # Expected: All rules moved to commit mode
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
}
```

#### 5.2 Duplicate Conflict Resolution Tests

```bash
test_resolve_duplicate_entries_commit_wins() {
    # Setup: Manually create duplicate entries (simulates user error)
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule1.mdc" --commit  # Should migrate, but manually add back to local
    
    # Manually add duplicate entry to simulate user editing error
    echo "rules/rule1.mdc" >> "$LOCAL_MANIFEST_FILE"
    
    # Test: Sync should resolve conflict
    cmd_sync
    
    # Expected: Commit mode wins, local entry silently removed
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    
    local_content=$(cat "$LOCAL_MANIFEST_FILE")
    echo "$local_content" | grep -q "rule1.mdc" && fail "Duplicate should be removed from local"
}
```

### Step 6: Enhanced Command Behavior Tests

**File**: `tests/unit/test_mode_operations.sh`

#### 6.1 List Command Three-State Display Tests

```bash
test_list_local_mode_only_glyphs() {
    # Setup: Local mode only with one rule
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: List should show local and uninstalled glyphs only
    output=$(cmd_list)
    
    # Expected: Shows ◐ for installed local rule, ○ for others
    echo "$output" | grep -q "$LOCAL_GLYPH.*rule1" || fail "Should show local glyph for rule1"
    echo "$output" | grep -q "$UNINSTALLED_GLYPH.*rule2" || fail "Should show uninstalled glyph for rule2"
    echo "$output" | grep -q "$COMMITTED_GLYPH" && fail "Should not show committed glyph in local-only mode"
}

test_list_commit_mode_only_glyphs() {
    # Setup: Commit mode only
    cmd_init "$SOURCE_REPO" --commit
    cmd_add_rule "rule1.mdc" --commit
    
    output=$(cmd_list)
    
    # Expected: Shows ● for committed rule, ○ for others  
    echo "$output" | grep -q "$COMMITTED_GLYPH.*rule1" || fail "Should show committed glyph for rule1"
    echo "$output" | grep -q "$UNINSTALLED_GLYPH.*rule2" || fail "Should show uninstalled glyph for rule2"
    echo "$output" | grep -q "$LOCAL_GLYPH" && fail "Should not show local glyph in commit-only mode"
}

test_list_dual_mode_all_glyphs() {
    # Setup: Both modes with different rules
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit  # Lazy init commit mode
    
    output=$(cmd_list)
    
    # Expected: Shows all three glyphs
    echo "$output" | grep -q "$LOCAL_GLYPH.*rule1" || fail "Should show local glyph for rule1"
    echo "$output" | grep -q "$COMMITTED_GLYPH.*rule2" || fail "Should show committed glyph for rule2"
    echo "$output" | grep -q "$UNINSTALLED_GLYPH.*rule3" || fail "Should show uninstalled glyph for rule3"
}
```

#### 6.2 Remove Command Mode Detection Tests

```bash
test_remove_rule_auto_detects_mode() {
    # Setup: Rule in local mode only
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: Remove without mode flag
    cmd_remove_rule "rule1.mdc"
    
    # Expected: Auto-detects and removes from local mode
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
}

test_remove_rule_from_correct_mode() {
    # Setup: Different rules in different modes
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Remove from each mode
    cmd_remove_rule "rule1.mdc"
    cmd_remove_rule "rule2.mdc"
    
    # Expected: Each removed from correct mode
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
}
```

#### 6.3 Sync Command Multi-Mode Tests

```bash
test_sync_all_initialized_modes() {
    # Setup: Both modes with rules
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Delete files to test sync restoration
    rm -f "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    rm -f "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
    
    # Test: Sync should restore both
    cmd_sync
    
    # Expected: Both files restored
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
}
```

### Step 7: Deinit Command Mode Selection Tests

**File**: `tests/unit/test_deinit_modes.sh`

#### 7.1 Selective Deinit Tests

```bash
test_deinit_local_mode_only() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit  # Creates both modes
    
    # Test: Deinit local mode only
    cmd_deinit --local
    
    # Expected: Local mode removed, commit mode preserved
    assert_file_not_exists "$LOCAL_MANIFEST_FILE"
    assert_commit_mode_exists
    assert_git_exclude_not_contains "$LOCAL_MANIFEST_FILE"
}

test_deinit_commit_mode_only() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit commit mode only
    cmd_deinit --commit
    
    # Expected: Commit mode removed, local mode preserved
    assert_file_not_exists "$COMMIT_MANIFEST_FILE"
    assert_local_mode_exists
}

test_deinit_all_modes() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit all modes
    cmd_deinit --all
    
    # Expected: Everything removed
    assert_no_modes_exist
    assertFalse "Target directory should be removed" "[ -d '$TARGET_DIR' ]"
}

test_deinit_requires_mode_selection() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit without mode flag
    output=$(cmd_deinit 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Error or prompt for mode selection
    echo "$output" | grep -q "mode\|local\|commit" || fail "Should require mode selection"
}
```

### Step 8: Backward Compatibility Migration Tests

**File**: `tests/unit/test_migration.sh`

#### 8.1 Legacy Local Mode Migration Tests

```bash
test_migrate_legacy_local_mode() {
    # Setup: Legacy local mode (ai-rizz.inf in git exclude)
    setup_legacy_local_repo
    
    # Test: Any command should trigger migration
    cmd_list
    
    # Expected: Migrated to new local mode structure
    assert_file_not_exists "$COMMIT_MANIFEST_FILE"
    assert_file_exists "$LOCAL_MANIFEST_FILE"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    
    # Verify git exclude updated
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$COMMIT_MANIFEST_FILE"
}

test_migrate_legacy_commit_mode() {
    # Setup: Legacy commit mode (ai-rizz.inf not in git exclude)
    setup_legacy_commit_repo
    
    # Test: Any command should preserve commit mode
    cmd_list
    
    # Expected: No migration needed, remains commit mode
    assert_file_exists "$COMMIT_MANIFEST_FILE"
    assert_file_not_exists "$LOCAL_MANIFEST_FILE"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
}

test_detect_legacy_local_mode() {
    # Test the detection logic for legacy local mode
    setup_legacy_local_repo
    
    # Test internal detection function
    assertTrue "Should detect legacy local mode" "needs_migration"
}

test_no_migration_needed_new_format() {
    # Setup: New format (both modes)
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: No migration should be needed
    assertFalse "Should not need migration" "needs_migration"
}
```

#### 8.2 Migration Preserves Data Tests

```bash
test_migration_preserves_all_rules() {
    # Setup: Legacy local with multiple rules
    setup_legacy_local_repo
    echo "rules/rule2.mdc" >> "$COMMIT_MANIFEST_FILE"
    cp "$REPO_DIR/rules/rule2.mdc" "$TARGET_DIR/$SHARED_DIR/"
    
    # Test: Migration preserves all rules
    cmd_list
    
    # Expected: All rules preserved in local mode
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    
    # Verify manifest content preserved
    local_content=$(cat "$LOCAL_MANIFEST_FILE")
    echo "$local_content" | grep -q "rules/rule1.mdc" || fail "Should preserve rule1"
    echo "$local_content" | grep -q "rules/rule2.mdc" || fail "Should preserve rule2"
}
```

### Step 9: Error Handling Tests

**File**: `tests/unit/test_error_handling.sh`

#### 9.1 Invalid State Error Tests

```bash
test_error_no_init_before_add() {
    # Setup: No initialization
    assert_no_modes_exist
    
    # Test: Add rule without init
    output=$(cmd_add_rule "rule1.mdc" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Clear error message with init suggestion
    echo "$output" | grep -q "init" || fail "Should suggest running init"
    echo "$output" | grep -q "configuration.*found" || fail "Should mention no configuration"
}

test_error_invalid_mode_flag() {
    # Setup: Valid repo
    cmd_init "$SOURCE_REPO" --local
    
    # Test: Invalid mode flag
    output=$(cmd_add_rule "rule1.mdc" --invalid 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Error about invalid mode
    echo "$output" | grep -q "invalid\|unknown" || fail "Should report invalid mode"
}

test_error_missing_source_repo() {
    # Test: Init without source repo
    output=$(cmd_init 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Error or prompt for source repo
    echo "$output" | grep -q "source\|repo\|URL" || fail "Should mention source repo"
}
```

#### 9.2 Graceful Degradation Tests

```bash
test_graceful_nonexistent_rule() {
    # Setup: Valid initialization
    cmd_init "$SOURCE_REPO" --local
    
    # Test: Add nonexistent rule
    output=$(cmd_add_rule "nonexistent.mdc" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Warning but not fatal error
    echo "$output" | grep -q "not found\|warning" || fail "Should warn about missing rule"
}

test_graceful_corrupted_manifest() {
    # Setup: Corrupted manifest
    cmd_init "$SOURCE_REPO" --local
    echo "CORRUPTED_DATA" > "$LOCAL_MANIFEST_FILE"
    
    # Test: Operations should handle gracefully
    output=$(cmd_list 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Error but clear message
    echo "$output" | grep -q "format\|corrupt\|invalid" || fail "Should report manifest issue"
}
```

### Step 10: Test Execution and Validation

#### 10.1 Test Runner Setup

Create comprehensive test runner script:

```bash
#!/bin/sh
# tests/run_phase1_tests.sh

echo "Running Phase 1 Unit Tests for Progressive Initialization"
echo "========================================================="
echo "Note: Some tests are expected to FAIL against current implementation"
echo

test_files="
test_progressive_init.sh
test_lazy_initialization.sh
test_mode_detection.sh
test_mode_operations.sh
test_conflict_resolution.sh
test_migration.sh
test_error_handling.sh
test_deinit_modes.sh
"

passed=0
failed=0
total=0

for test_file in $test_files; do
    echo "Running tests/unit/$test_file..."
    if sh "tests/unit/$test_file"; then
        passed=$((passed + 1))
        echo "✓ PASSED"
    else
        failed=$((failed + 1))
        echo "✗ FAILED (Expected for Phase 1)"
    fi
    total=$((total + 1))
    echo
done

echo "========================================================="
echo "Test Results: $passed passed, $failed failed, $total total"
echo "Failed tests represent new behavior not yet implemented."
echo "This is expected and validates test completeness."
```

#### 10.2 Expected Failure Analysis

Document which tests should fail and why:

1. **Progressive Init Tests**: Will fail because current `cmd_init` doesn't support `--local`/`--commit` flags
2. **Lazy Initialization Tests**: Will fail because current system doesn't auto-create modes
3. **Three-State Glyph Tests**: Will fail because current system only has two states
4. **Mode Migration Tests**: Will fail because current system doesn't support mode migration
5. **Dual-Mode Tests**: Will fail because current system is single-mode only

#### 10.3 Test Validation Criteria

**Success Criteria for Phase 1**:
- All test files execute without shell syntax errors
- Tests actually invoke ai-rizz commands (not just mock functions)  
- Expected failures occur (validates we're testing real behavior changes)
- Test coverage includes all major new features from design
- Tests are deterministic and use proper temp directory isolation

### Step 11: Clean Up Legacy Tests

**Final Step**: Remove old test files that test the current single-mode behavior

```bash
# Remove existing test files that validate old behavior
rm tests/unit/sync_shunit.test.sh
rm tests/unit/manifest_shunit.test.sh
```

**Important**: This ensures that after Phase 1 completion, we only have tests that validate the new progressive initialization behavior. The old tests would create confusion and potentially false passes/fails during Phase 2+ development.

## Success Metrics

1. **Comprehensive Coverage**: Tests cover all major features from design document
2. **Meaningful Failures**: Expected test failures validate behavioral changes  
3. **Proper Isolation**: Each test uses temp directories and cleans up properly
4. **Actual Behavior Testing**: Tests invoke real ai-rizz commands, not mock functions
5. **Clear Documentation**: Each test documents expected behavior vs current behavior
6. **Future Compatibility**: Tests will pass once Phase 2+ implementation is complete

## Next Phase Preparation

These tests will serve as the specification and validation for Phase 2 implementation. The test failures will guide the implementation priorities and ensure all new features work correctly.

**Phase 2 Goal**: Implement the core infrastructure so these tests begin passing. 