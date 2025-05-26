#!/bin/sh
# Tests for mode detection and smart defaults using shunit2

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Main test functions
# ------------------

test_detect_local_mode_only() {
    # Setup: Local mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    
    # Test internal mode detection functions
    # These test the new utility functions that will be added
    assertTrue "Should detect local mode" "has_local_mode"
    assertFalse "Should not detect commit mode" "has_commit_mode"
}

test_detect_commit_mode_only() {
    # Setup: Commit mode only  
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    
    assertTrue "Should detect commit mode" "has_commit_mode"
    assertFalse "Should not detect local mode" "has_local_mode"
}

test_detect_dual_mode() {
    # Setup: Both modes via lazy init
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit  # Triggers lazy init
    
    assertTrue "Should detect local mode" "has_local_mode"
    assertTrue "Should detect commit mode" "has_commit_mode"
}

test_detect_no_modes() {
    # Setup: No initialization
    assert_no_modes_exist
    
    # Test mode detection with no manifests
    assertFalse "Should not detect local mode" "has_local_mode"
    assertFalse "Should not detect commit mode" "has_commit_mode"
}

test_add_rule_single_mode_auto_select() {
    # Setup: Local mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    
    # Test: Add rule without mode flag
    cmd_add_rule "rule1.mdc"
    
    # Expected: Automatically uses local mode
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
}

test_add_rule_dual_mode_requires_flag() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit  # Creates dual mode
    
    # Test: Add rule without mode flag (provide empty input to prompt)
    output=$(echo "" | cmd_add_rule "rule2.mdc" 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should prompt for mode specification
    echo "$output" | grep -q "mode\|local\|commit\|choose\|select" || fail "Should prompt for mode specification"
}

test_add_ruleset_single_mode_auto_select() {
    # Setup: Commit mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    
    # Test: Add ruleset without mode flag
    cmd_add_ruleset "ruleset1"
    
    # Expected: Automatically uses commit mode
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
}

test_add_ruleset_dual_mode_requires_flag() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    cmd_add_rule "rule1.mdc" --local  # Creates dual mode
    
    # Test: Add ruleset without mode flag (provide empty input to prompt)
    output=$(echo "" | cmd_add_ruleset "ruleset1" 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should prompt for mode specification
    echo "$output" | grep -q "mode\|local\|commit\|choose\|select" || fail "Should prompt for mode specification"
}

test_mode_detection_with_custom_target() {
    # Setup: Custom target directory in local mode
    custom_dir=".custom/rules"
    cmd_init "$SOURCE_REPO" -d "$custom_dir" --local
    
    # Test: Mode detection should work with custom paths
    assertTrue "Should detect local mode with custom dir" "has_local_mode"
    assertFalse "Should not detect commit mode" "has_commit_mode"
}

test_mode_detection_after_deinit() {
    # Setup: Both modes exist
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    assertTrue "Should detect both modes" "has_local_mode && has_commit_mode"
    
    # Test: Deinit one mode
    cmd_deinit --local -y
    
    # Expected: Should only detect commit mode
    assertFalse "Should not detect local mode after deinit" "has_local_mode"
    assertTrue "Should still detect commit mode" "has_commit_mode"
}

test_smart_mode_selection_prefers_existing() {
    # Setup: Local mode with existing rules
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: Adding without mode flag should use existing mode
    cmd_add_rule "rule2.mdc"
    
    # Expected: New rule added to existing local mode
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
}

test_mode_detection_git_exclude_accuracy() {
    # Setup: Local mode
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    
    # Test: Git exclude should contain local files
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TARGET_DIR/$LOCAL_DIR"
    
    # Test: Git exclude should NOT contain commit files
    assert_git_exclude_not_contains "$COMMIT_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TARGET_DIR/$SHARED_DIR"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 