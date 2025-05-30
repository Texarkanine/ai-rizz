#!/bin/sh
#
# test_initialization.test.sh - Comprehensive initialization test suite
#
# Tests all aspects of ai-rizz initialization including progressive initialization,
# lazy initialization, mode detection, and smart defaults. Validates the complete
# initialization lifecycle from initial setup through dual-mode transitions with
# proper directory structure, manifest creation, git exclude management, and
# idempotent behavior.
#
# Test Coverage:
# - Progressive initialization (single mode → dual mode)
# - Lazy initialization (auto-create missing modes)
# - Mode detection and smart command defaults
# - Custom target directories and manifest filenames
# - Git exclude management across modes
# - Idempotent re-initialization behavior
# - Error handling for uninitialized states
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_initialization.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# PROGRESSIVE INITIALIZATION TESTS
# ============================================================================

test_init_local_mode_only() {
    # Test: ai-rizz init $REPO -d $TEST_TARGET_DIR --local
    # Expected: Creates local manifest and directory only
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    assert_local_mode_exists
    assert_file_not_exists "$TEST_COMMIT_MANIFEST_FILE"
    assert_git_exclude_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
    
    # Verify mode detection
    assertTrue "Should detect local mode" "[ \"$(is_mode_active local)\" = \"true\" ]"
    assertFalse "Should not detect commit mode" "[ \"$(is_mode_active commit)\" = \"true\" ]"
}

test_init_commit_mode_only() {
    # Test: ai-rizz init $REPO -d $TEST_TARGET_DIR --commit  
    # Expected: Creates commit manifest and directory only
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    
    assert_commit_mode_exists
    assert_file_not_exists "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TEST_COMMIT_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TEST_TARGET_DIR/$TEST_SHARED_DIR"
    
    # Verify mode detection
    assertTrue "Should detect commit mode" "[ \"$(is_mode_active commit)\" = \"true\" ]"
    assertFalse "Should not detect local mode" "[ \"$(is_mode_active local)\" = \"true\" ]"
}

test_init_requires_mode_flag() {
    # Test: ai-rizz init $REPO (no mode flag, provide empty input to prompt)
    # Expected: Should prompt for mode selection
    
    output=$(echo "" | cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should show prompt for mode selection
    echo "$output" | grep -q "mode\|local\|commit\|choose\|select" || fail "Should show mode selection prompt"
}

test_init_custom_target_dir() {
    # Test: ai-rizz init $REPO -d .custom/rules --local
    # Expected: Uses custom target directory
    
    custom_dir=".custom/rules"
    cmd_init "$TEST_SOURCE_REPO" -d "$custom_dir" --local
    
    assertTrue "Custom directory should exist" "[ -d '$custom_dir/$TEST_LOCAL_DIR' ]"
    assert_git_exclude_contains "$custom_dir/$TEST_LOCAL_DIR"
    
    # Verify mode detection works with custom paths
    assertTrue "Should detect local mode with custom dir" "[ \"$(is_mode_active local)\" = \"true\" ]"
}

test_init_creates_correct_manifest_headers() {
    # Test both modes create proper headers
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    first_line=$(head -n1 "$TEST_LOCAL_MANIFEST_FILE")
    assertEquals "Local manifest header incorrect" "$TEST_SOURCE_REPO	$TEST_TARGET_DIR	rules	rulesets" "$first_line"
    
    # Clean up and test commit mode in separate directory
    tearDown
    setUp
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit  
    first_line=$(head -n1 "$TEST_COMMIT_MANIFEST_FILE")
    assertEquals "Commit manifest header incorrect" "$TEST_SOURCE_REPO	$TEST_TARGET_DIR	rules	rulesets" "$first_line"
}

test_init_twice_same_mode_idempotent() {
    # Test: Running init twice with same mode should be idempotent
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    assert_local_mode_exists
    
    # Init again with same mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    assert_local_mode_exists
    
    # Should still only have local mode
    assert_file_not_exists "$TEST_COMMIT_MANIFEST_FILE"
    assertFalse "Should not create commit mode" "[ \"$(is_mode_active commit)\" = \"true\" ]"
}

test_init_different_modes_creates_dual_mode() {
    # Test: First init with local, then commit → creates dual mode
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    assert_local_mode_exists
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    
    # Verify both modes exist
    assert_local_mode_exists
    assert_commit_mode_exists
    assertTrue "Should detect both modes" "[ \"$(is_mode_active local)\" = \"true\" ] && [ \"$(is_mode_active commit)\" = \"true\" ]"
}

# ============================================================================
# LAZY INITIALIZATION TESTS
# ============================================================================

test_lazy_init_local_from_commit() {
    # Setup: Only commit mode exists
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    assert_commit_mode_exists
    assert_file_not_exists "$TEST_LOCAL_MANIFEST_FILE"
    
    # Test: Add rule to local mode (should auto-create local mode)
    cmd_add_rule "rule1.mdc" --local
    
    # Expected: Local mode created, rule added to local
    assert_local_mode_exists
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule1.mdc"
    
    # Verify local manifest has correct header copied from commit manifest
    local_header=$(head -n1 "$TEST_LOCAL_MANIFEST_FILE")
    commit_header=$(head -n1 "$TEST_COMMIT_MANIFEST_FILE") 
    assertEquals "Headers should match" "$commit_header" "$local_header"
    
    # Verify mode detection updated
    assertTrue "Should detect both modes" "[ \"$(is_mode_active local)\" = \"true\" ] && [ \"$(is_mode_active commit)\" = \"true\" ]"
}

test_lazy_init_commit_from_local() {
    # Setup: Only local mode exists
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    assert_local_mode_exists
    assert_file_not_exists "$TEST_COMMIT_MANIFEST_FILE"
    
    # Test: Add rule to commit mode (should auto-create commit mode)
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Commit mode created, rule added to commit
    assert_commit_mode_exists
    assert_file_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule1.mdc"
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    
    # Verify mode detection updated
    assertTrue "Should detect both modes" "[ \"$(is_mode_active local)\" = \"true\" ] && [ \"$(is_mode_active commit)\" = \"true\" ]"
}

test_lazy_init_preserves_existing_rules() {
    # Setup: Local mode with existing rule
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule2.mdc" --local
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc"
    
    # Test: Add rule to commit mode
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Both rules exist in their respective modes
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc"
    assert_file_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule1.mdc"
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
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    
    # Test: Add ruleset to local mode
    cmd_add_ruleset "ruleset1" --local
    
    # Expected: Local mode created, all ruleset rules copied to local
    assert_local_mode_exists
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc"
}

test_lazy_init_copies_target_dir() {
    # Setup: Commit mode with custom target directory
    custom_dir=".custom/rules"
    cmd_init "$TEST_SOURCE_REPO" -d "$custom_dir" --commit
    
    # Test: Add rule to local mode should use same target directory
    cmd_add_rule "rule1.mdc" --local
    
    # Expected: Local mode uses same custom target directory
    assertTrue "Should use same custom target dir" "[ -d '$custom_dir/$TEST_LOCAL_DIR' ]"
    assert_file_exists "$custom_dir/$TEST_LOCAL_DIR/rule1.mdc"
}

test_lazy_init_creates_git_excludes() {
    # Setup: Commit mode only (no git excludes)
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    assert_git_exclude_not_contains "$TEST_LOCAL_MANIFEST_FILE"
    
    # Test: Add rule to local mode
    cmd_add_rule "rule1.mdc" --local
    
    # Expected: Git excludes created for local mode
    assert_git_exclude_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
}

test_lazy_init_preserves_manifest_entries() {
    # Setup: Local mode with existing entries
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule2.mdc" --local
    cmd_add_ruleset "ruleset1" --local
    
    # Test: Add rule to commit mode
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Local manifest still has original entries
    local_content=$(cat "$TEST_LOCAL_MANIFEST_FILE")
    echo "$local_content" | grep -q "rules/rule2.mdc" || fail "Should preserve rule2 in local"
    echo "$local_content" | grep -q "rulesets/ruleset1" || fail "Should preserve ruleset1 in local"
    
    # Commit manifest should have new entry
    commit_content=$(cat "$TEST_COMMIT_MANIFEST_FILE")
    echo "$commit_content" | grep -q "rules/rule1.mdc" || fail "Should have rule1 in commit"
}

test_lazy_init_no_cross_contamination() {
    # Setup: Both modes via lazy init
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Rules should be in correct modes only
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule1.mdc"
    
    assert_file_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule2.mdc"
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc"
}

# ============================================================================
# MODE DETECTION AND SMART DEFAULTS TESTS
# ============================================================================

test_mode_detection_no_modes() {
    # Setup: No initialization
    assert_no_modes_exist
    
    # Test mode detection with no manifests
    assertFalse "Should not detect local mode" "[ \"$(is_mode_active local)\" = \"true\" ]"
    assertFalse "Should not detect commit mode" "[ \"$(is_mode_active commit)\" = \"true\" ]"
}

test_add_rule_single_mode_auto_select() {
    # Setup: Local mode only
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Test: Add rule without mode flag
    cmd_add_rule "rule1.mdc"
    
    # Expected: Automatically uses local mode
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule1.mdc"
}

test_add_rule_dual_mode_requires_flag() {
    # Setup: Both modes exist
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit  # Creates dual mode
    
    # Test: Add rule without mode flag (provide empty input to prompt)
    output=$(echo "" | cmd_add_rule "rule2.mdc" 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should prompt for mode specification
    echo "$output" | grep -q "mode\|local\|commit\|choose\|select" || fail "Should prompt for mode specification"
}

test_add_ruleset_single_mode_auto_select() {
    # Setup: Commit mode only
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    
    # Test: Add ruleset without mode flag
    cmd_add_ruleset "ruleset1"
    
    # Expected: Automatically uses commit mode
    assert_file_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule1.mdc"
    assert_file_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule2.mdc"
}

test_add_ruleset_dual_mode_requires_flag() {
    # Setup: Both modes exist
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    cmd_add_rule "rule1.mdc" --local  # Creates dual mode
    
    # Test: Add ruleset without mode flag (provide empty input to prompt)
    output=$(echo "" | cmd_add_ruleset "ruleset1" 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should prompt for mode specification
    echo "$output" | grep -q "mode\|local\|commit\|choose\|select" || fail "Should prompt for mode specification"
}

test_mode_detection_after_deinit() {
    # Setup: Both modes exist
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    assertTrue "Should detect both modes" "[ \"$(is_mode_active local)\" = \"true\" ] && [ \"$(is_mode_active commit)\" = \"true\" ]"
    
    # Test: Deinit one mode
    cmd_deinit --local -y
    
    # Expected: Should only detect commit mode
    assertFalse "Should not detect local mode after deinit" "[ \"$(is_mode_active local)\" = \"true\" ]"
    assertTrue "Should still detect commit mode" "[ \"$(is_mode_active commit)\" = \"true\" ]"
}

test_smart_mode_selection_prefers_existing() {
    # Setup: Local mode with existing rules
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: Adding without mode flag should use existing mode
    cmd_add_rule "rule2.mdc"
    
    # Expected: New rule added to existing local mode
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc"
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule2.mdc"
}

test_mode_detection_git_exclude_accuracy() {
    # Setup: Local mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Test: Git exclude should contain local files
    assert_git_exclude_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
    
    # Test: Git exclude should NOT contain commit files
    assert_git_exclude_not_contains "$TEST_COMMIT_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TEST_TARGET_DIR/$TEST_SHARED_DIR"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 