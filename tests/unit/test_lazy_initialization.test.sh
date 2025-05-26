#!/bin/sh
# Tests for lazy initialization functionality using shunit2

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Main test functions
# ------------------

test_lazy_init_local_from_commit() {
    # Setup: Only commit mode exists
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
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
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
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
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
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
    echo "$output" | grep -q "Run.*init.*first" || fail "Should suggest running init"
}

test_lazy_init_with_rulesets() {
    # Setup: Commit mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    
    # Test: Add ruleset to local mode
    cmd_add_ruleset "ruleset1" --local
    
    # Expected: Local mode created, all ruleset rules copied to local
    assert_local_mode_exists
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
}

test_lazy_init_copies_target_dir() {
    # Setup: Commit mode with custom target directory
    custom_dir=".custom/rules"
    cmd_init "$SOURCE_REPO" -d "$custom_dir" --commit
    
    # Test: Add rule to local mode should use same target directory
    cmd_add_rule "rule1.mdc" --local
    
    # Expected: Local mode uses same custom target directory
    assertTrue "Should use same custom target dir" "[ -d '$custom_dir/$LOCAL_DIR' ]"
    assert_file_exists "$custom_dir/$LOCAL_DIR/rule1.mdc"
}

test_lazy_init_creates_git_excludes() {
    # Setup: Commit mode only (no git excludes)
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    assert_git_exclude_not_contains "$LOCAL_MANIFEST_FILE"
    
    # Test: Add rule to local mode
    cmd_add_rule "rule1.mdc" --local
    
    # Expected: Git excludes created for local mode
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TARGET_DIR/$LOCAL_DIR"
}

test_lazy_init_preserves_manifest_entries() {
    # Setup: Local mode with existing entries
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule2.mdc" --local
    cmd_add_ruleset "ruleset1" --local
    
    # Test: Add rule to commit mode
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Local manifest still has original entries
    local_content=$(cat "$LOCAL_MANIFEST_FILE")
    echo "$local_content" | grep -q "rules/rule2.mdc" || fail "Should preserve rule2 in local"
    echo "$local_content" | grep -q "rulesets/ruleset1" || fail "Should preserve ruleset1 in local"
    
    # Commit manifest should have new entry
    commit_content=$(cat "$COMMIT_MANIFEST_FILE")
    echo "$commit_content" | grep -q "rules/rule1.mdc" || fail "Should have rule1 in commit"
}

test_lazy_init_no_cross_contamination() {
    # Setup: Both modes via lazy init
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Rules should be in correct modes only
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 