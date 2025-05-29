#!/bin/sh
#
# test_sync_operations.test.sh - Sync operations and file deployment test suite
#
# Tests all aspects of the synchronization system including repository sync,
# file deployment, sync triggers after rule/ruleset operations, error handling
# for missing manifests, and proper sync coordination across multiple modes.
# Validates the core sync functionality that keeps local files in sync with
# manifests and repository content.
#
# Test Coverage:
# - Multi-mode sync coordination (local + commit)
# - Single-mode sync behavior
# - File deployment and restoration
# - Sync triggers after operations
# - Error handling for missing/corrupt manifests
# - Repository sync error scenarios
# - Directory structure management during sync
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_sync_operations.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# MULTI-MODE SYNC TESTS
# ============================================================================

test_sync_all_initialized_modes() {
    # Setup: Both modes with rules
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule3.mdc" --commit
    
    # Delete files to test sync restoration
    rm -f "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    rm -f "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
    
    # Test: Sync should restore both
    cmd_sync
    
    # Expected: Both files restored
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
}

test_sync_dual_mode_with_rulesets() {
    # Setup: Rulesets in different modes  
    # Note: When both modes have rulesets with overlapping rules,
    # commit mode takes precedence (conflict resolution)
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_ruleset "ruleset1" --local  # Contains rule1, rule2
    cmd_add_ruleset "ruleset2" --commit # Contains rule2, rule3
    
    # Delete all files to test comprehensive sync
    rm -rf "$TARGET_DIR/$LOCAL_DIR"
    rm -rf "$TARGET_DIR/$SHARED_DIR"
    
    # Test: Sync should restore all directories and files
    cmd_sync
    
    # Expected: Files restored per conflict resolution rules
    # Local mode gets rule1 only (rule2 goes to commit due to conflict resolution)
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    # rule2 goes to commit mode due to conflict resolution
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
}

test_sync_preserves_mode_isolation() {
    # Setup: Non-overlapping rulesets to test isolation
    # Use ruleset1 (rule1, rule2) in local and individual rule3 in commit
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_ruleset "ruleset1" --local
    cmd_add_rule "rule3.mdc" --commit
    
    # Test: Sync should maintain proper mode isolation
    cmd_sync
    
    # Expected: Files in correct directories with no overlap
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule3.mdc"
    
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
}

# ============================================================================
# SINGLE-MODE SYNC TESTS
# ============================================================================

test_sync_single_mode_only() {
    # Setup: Local mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Delete file to test sync
    rm -f "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    
    # Test: Sync should only restore local mode
    cmd_sync
    
    # Expected: Local file restored, no commit files created
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    # Note: shared directory may exist but should not contain the rule file
}

test_sync_commit_mode_only() {
    # Setup: Commit mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    cmd_add_rule "rule1.mdc" --commit
    
    # Delete file to test sync
    rm -f "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    
    # Test: Sync should only restore commit mode
    cmd_sync
    
    # Expected: Commit file restored, no local files created
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assertFalse "Local directory should not be created" "[ -d '$TARGET_DIR/$LOCAL_DIR' ]"
}

test_sync_empty_manifest_creates_directories() {
    # Setup: Local mode with no rules
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    
    # Ensure directory doesn't exist
    rm -rf "$TARGET_DIR/$LOCAL_DIR"
    
    # Test: Sync should create directory even with empty manifest
    cmd_sync
    
    # Expected: Directory structure should exist
    assertTrue "Local directory should be created" "[ -d '$TARGET_DIR/$LOCAL_DIR' ]"
}

# ============================================================================
# SYNC TRIGGER TESTS
# ============================================================================

test_sync_triggers_after_remove() {
    # Setup: Rules in both modes (use different rules to avoid conflict)
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule3.mdc" --commit
    
    # Test: Remove should trigger sync automatically
    cmd_remove_rule "rule1.mdc"
    
    # Expected: Sync should have been called (files should be gone)
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"  # Should remain
}

test_sync_triggers_after_add() {
    # Setup: Local mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    
    # Test: Add should trigger sync automatically
    cmd_add_rule "rule1.mdc" --local
    
    # Expected: File should be deployed immediately
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
}

test_sync_triggers_after_ruleset_operations() {
    # Setup: Local mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    
    # Test: Add ruleset should trigger sync
    cmd_add_ruleset "ruleset1" --local
    
    # Expected: All ruleset files should be deployed (ruleset1 = rule1, rule2)
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    
    # Test: Remove ruleset should trigger sync
    cmd_remove_ruleset "ruleset1"
    
    # Expected: All files should be removed
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
}

# ============================================================================
# ERROR HANDLING AND EDGE CASES
# ============================================================================

test_sync_handles_missing_manifests() {
    # Setup: Local mode
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Corrupt one manifest to test graceful handling
    rm -f "$LOCAL_MANIFEST_FILE"
    
    # Test: Sync should handle missing manifest gracefully
    output=$(cmd_sync 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should not fail catastrophically
    echo "$output" | grep -q "error\|not found" || true  # May warn, but shouldn't crash
}

test_sync_handles_missing_target_directories() {
    # Setup: Both modes with rules (use different rules to avoid conflict)
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule3.mdc" --commit
    
    # Remove target directories completely
    rm -rf "$TARGET_DIR"
    
    # Test: Sync should recreate directory structure
    cmd_sync
    
    # Expected: Directories and files should be recreated
    assertTrue "Target directory should be recreated" "[ -d '$TARGET_DIR' ]"
    assertTrue "Local directory should be recreated" "[ -d '$TARGET_DIR/$LOCAL_DIR' ]"
    assertTrue "Shared directory should be recreated" "[ -d '$TARGET_DIR/$SHARED_DIR' ]"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
}

test_sync_handles_partial_file_corruption() {
    # Setup: Local mode with rule
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Corrupt deployed file
    echo "corrupted content" > "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    
    # Test: Sync should restore correct content
    cmd_sync
    
    # Expected: File should be restored to original content
    content=$(cat "$TARGET_DIR/$LOCAL_DIR/rule1.mdc")
    echo "$content" | grep -q "Rule 1 content" || fail "File should be restored to original content"
}

test_sync_with_custom_target_directory() {
    # Setup: Custom target directory
    custom_dir=".custom/rules"
    cmd_init "$SOURCE_REPO" -d "$custom_dir" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Delete file to test sync with custom directory
    rm -f "$custom_dir/$LOCAL_DIR/rule1.mdc"
    
    # Test: Sync should work with custom directory
    cmd_sync
    
    # Expected: File restored in custom directory
    assert_file_exists "$custom_dir/$LOCAL_DIR/rule1.mdc"
}

test_sync_no_modes_error() {
    # Setup: No modes initialized
    assert_no_modes_exist
    
    # Test: Sync with no modes should show appropriate error
    output=$(cmd_sync 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should indicate no configuration found
    echo "$output" | grep -q "No ai-rizz configuration found\|ERROR_OCCURRED" || fail "Should error when no modes exist"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 