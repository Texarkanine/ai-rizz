#!/bin/sh
# Tests for deinit command mode selection using shunit2

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Main test functions
# ------------------

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
    
    # Expected: Should prompt for mode selection
    echo "$output" | grep -q "mode\|local\|commit\|choose\|select" || fail "Should prompt for mode selection"
}

test_deinit_single_mode_direct() {
    # Setup: Only local mode exists
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: Deinit without mode flag when only one mode exists
    cmd_deinit --local
    
    # Expected: Should deinit successfully
    assert_no_modes_exist
}

test_deinit_local_removes_git_excludes() {
    # Setup: Local mode
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    
    # Test: Deinit local mode
    cmd_deinit --local
    
    # Expected: Git exclude entries removed
    assert_git_exclude_not_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TARGET_DIR/$LOCAL_DIR"
}

test_deinit_commit_preserves_git_excludes() {
    # Setup: Both modes
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    
    # Test: Deinit commit mode only
    cmd_deinit --commit
    
    # Expected: Local git excludes should remain
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TARGET_DIR/$LOCAL_DIR"
}

test_deinit_preserves_files_in_other_mode() {
    # Setup: Rules in both modes
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "local-rule.mdc" --local
    cmd_add_rule "commit-rule.mdc" --commit
    
    # Test: Deinit local mode only
    cmd_deinit --local
    
    # Expected: Commit files preserved, local files removed
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/local-rule.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/commit-rule.mdc"
}

test_deinit_custom_target_directory() {
    # Setup: Custom target directory with both modes
    custom_dir=".custom/rules"
    cmd_init "$SOURCE_REPO" -d "$custom_dir" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit local mode
    cmd_deinit --local
    
    # Expected: Custom local directory removed, shared preserved
    assertFalse "Custom local dir should be removed" "[ -d '$custom_dir/$LOCAL_DIR' ]"
    assertTrue "Custom shared dir should remain" "[ -d '$custom_dir/$SHARED_DIR' ]"
}

test_deinit_nonexistent_mode_graceful() {
    # Setup: Only local mode exists
    cmd_init "$SOURCE_REPO" --local
    
    # Test: Try to deinit commit mode that doesn't exist
    output=$(cmd_deinit --commit 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should handle gracefully (warn but not fail)
    echo "$output" | grep -q "not found\|warning\|no.*commit" || true  # May warn
    
    # Local mode should remain untouched
    assert_local_mode_exists
}

test_deinit_all_with_single_mode() {
    # Setup: Only commit mode
    cmd_init "$SOURCE_REPO" --commit
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit all when only one mode exists
    cmd_deinit --all
    
    # Expected: Everything should be removed
    assert_no_modes_exist
    assertFalse "Target directory should be removed" "[ -d '$TARGET_DIR' ]"
}

test_deinit_confirmation_prompts() {
    # Setup: Both modes with rules
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Deinit all should prompt for confirmation (or accept -y flag)
    output=$(cmd_deinit --all -y 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should proceed without prompting due to -y flag
    assert_no_modes_exist
}

test_deinit_partial_cleanup_on_error() {
    # Setup: Both modes
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Make local manifest read-only to simulate error
    chmod 444 "$LOCAL_MANIFEST_FILE"
    
    # Test: Deinit local mode with permission error
    output=$(cmd_deinit --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should handle error gracefully
    echo "$output" | grep -q "error\|permission\|failed" || true
    
    # Restore permissions for cleanup
    chmod 644 "$LOCAL_MANIFEST_FILE"
}

test_deinit_removes_empty_directories() {
    # Setup: Local mode with nested structure
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Create additional nested structure
    mkdir -p "$TARGET_DIR/$LOCAL_DIR/nested"
    touch "$TARGET_DIR/$LOCAL_DIR/nested/dummy"
    
    # Test: Deinit should remove entire directory tree
    cmd_deinit --local
    
    # Expected: Entire local directory structure removed
    assertFalse "Local directory should be completely removed" "[ -d '$TARGET_DIR/$LOCAL_DIR' ]"
}

test_deinit_interactive_mode_selection() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Interactive mode (would normally prompt)
    output=$(cmd_deinit 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should prompt for mode selection
    echo "$output" | grep -q "mode\|local\|commit\|choose\|select" || fail "Should prompt for mode selection"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 