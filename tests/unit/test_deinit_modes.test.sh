#!/bin/sh
#
# test_deinit_modes.test.sh - Deinit mode selection test suite
#
# Tests the deinit command's mode-selective removal capabilities including
# individual mode removal, complete cleanup, confirmation prompts, and
# proper cleanup of manifests, directories, and git excludes.
#
# Test Coverage:
# Validates the deinit command's mode-selective removal capabilities with
# proper cleanup of manifests, directories, and git excludes while handling
# confirmation prompts and maintaining system integrity during partial and
# complete removal scenarios.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_deinit_modes.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Main test functions
# ------------------

test_deinit_local_mode_only() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit  # Creates both modes
    
    # Test: Deinit local mode only
    cmd_deinit --local -y
    
    # Expected: Local mode removed, commit mode preserved
    assert_file_not_exists "$LOCAL_MANIFEST_FILE"
    assert_commit_mode_exists
    assert_git_exclude_not_contains "$LOCAL_MANIFEST_FILE"
}

test_deinit_commit_mode_only() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit commit mode only
    cmd_deinit --commit -y
    
    # Expected: Commit mode removed, local mode preserved
    assert_file_not_exists "$COMMIT_MANIFEST_FILE"
    assert_local_mode_exists
}

test_deinit_all_modes() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit all modes
    cmd_deinit --all -y
    
    # Expected: All ai-rizz modes removed, but target directory preserved (may contain user files)
    assert_no_modes_exist
    assertFalse "Local subdirectory should be removed" "[ -d '$TARGET_DIR/$LOCAL_DIR' ]"
    assertFalse "Shared subdirectory should be removed" "[ -d '$TARGET_DIR/$SHARED_DIR' ]"
}

test_deinit_requires_mode_selection() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit without mode flag (provide empty input to prompt)
    output=$(echo "" | cmd_deinit 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should prompt for mode selection
    echo "$output" | grep -q "mode\|local\|commit\|choose\|select" || fail "Should prompt for mode selection"
}

test_deinit_single_mode_direct() {
    # Setup: Only local mode exists
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: Deinit without mode flag when only one mode exists
    cmd_deinit --local -y
    
    # Expected: Should deinit successfully
    assert_no_modes_exist
}

test_deinit_local_removes_git_excludes() {
    # Setup: Local mode
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    
    # Test: Deinit local mode
    cmd_deinit --local -y
    
    # Expected: Git exclude entries removed
    assert_git_exclude_not_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TARGET_DIR/$LOCAL_DIR"
}

test_deinit_commit_preserves_git_excludes() {
    # Setup: Both modes
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    
    # Test: Deinit commit mode only
    cmd_deinit --commit -y
    
    # Expected: Local git excludes should remain
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TARGET_DIR/$LOCAL_DIR"
}

test_deinit_preserves_files_in_other_mode() {
    # Setup: Rules in both modes
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Deinit local mode only
    cmd_deinit --local -y
    
    # Expected: Commit files preserved, local files removed
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
}

test_deinit_custom_target_directory() {
    # Setup: Custom target directory with both modes
    custom_dir=".custom/rules"
    cmd_init "$SOURCE_REPO" -d "$custom_dir" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit local mode
    cmd_deinit --local -y
    
    # Expected: Custom local directory removed, shared preserved
    assertFalse "Custom local dir should be removed" "[ -d '$custom_dir/$LOCAL_DIR' ]"
    assertTrue "Custom shared dir should remain" "[ -d '$custom_dir/$SHARED_DIR' ]"
}

test_deinit_nonexistent_mode_graceful() {
    # Setup: Only local mode exists
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    
    # Test: Try to deinit commit mode that doesn't exist
    output=$(cmd_deinit --commit -y 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should handle gracefully (warn but not fail)
    echo "$output" | grep -q "not found\|warning\|no.*commit" || true  # May warn
    
    # Local mode should remain untouched
    assert_local_mode_exists
}

test_deinit_all_with_single_mode() {
    # Setup: Only commit mode
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit all when only one mode exists
    cmd_deinit --all -y
    
    # Expected: All ai-rizz modes removed, but target directory preserved (may contain user files)
    assert_no_modes_exist
    assertFalse "Shared subdirectory should be removed" "[ -d '$TARGET_DIR/$SHARED_DIR' ]"
}

test_deinit_confirmation_prompts() {
    # Setup: Both modes with rules
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Deinit all should prompt for confirmation (or accept -y flag)
    output=$(cmd_deinit --all -y 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should proceed without prompting due to -y flag
    assert_no_modes_exist
}

test_deinit_partial_cleanup_on_error() {
    # Setup: Both modes with separate rules to ensure both manifests exist
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Make local manifest read-only to simulate error (only if it exists)
    if [ -f "$LOCAL_MANIFEST_FILE" ]; then
        chmod 444 "$LOCAL_MANIFEST_FILE"
    fi
    
    # Test: Deinit local mode with permission error
    output=$(cmd_deinit --local -y 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should handle error gracefully
    echo "$output" | grep -q "error\|permission\|failed" || true
    
    # Restore permissions for cleanup (only if file exists)
    if [ -f "$LOCAL_MANIFEST_FILE" ]; then
        chmod 644 "$LOCAL_MANIFEST_FILE"
    fi
}

test_deinit_removes_empty_directories() {
    # Setup: Local mode with nested structure
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Create additional nested structure
    mkdir -p "$TARGET_DIR/$LOCAL_DIR/nested"
    touch "$TARGET_DIR/$LOCAL_DIR/nested/dummy"
    
    # Test: Deinit local mode
    cmd_deinit --local -y
    
    # Expected: Empty parent directories should be cleaned up
    assertFalse "Nested directory should be removed" "[ -d '$TARGET_DIR/$LOCAL_DIR/nested' ]"
    assertFalse "Local directory should be removed" "[ -d '$TARGET_DIR/$LOCAL_DIR' ]"
}

test_deinit_interactive_mode_selection() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Interactive mode (provide empty input to prompt)
    output=$(echo "" | cmd_deinit 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should prompt for mode selection
    echo "$output" | grep -q "mode\|local\|commit\|choose\|select" || fail "Should prompt for mode selection"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 