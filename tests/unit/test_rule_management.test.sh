#!/bin/sh
#
# test_rule_management.test.sh - Individual rule management test suite
#
# Tests all operations related to individual rule management including add/remove
# behavior, mode auto-detection, listing with status glyphs, error handling for
# nonexistent rules, and proper manifest updates. Validates rule-specific command
# interface with proper mode handling and constraint enforcement.
#
# Test Coverage:
# - Individual rule add/remove operations
# - Mode auto-detection for rule operations
# - Status display and listing with glyphs
# - Error handling for nonexistent rules
# - Manifest updates after rule operations
# - Custom directory support for rule operations
# - Cross-mode rule behavior and conflicts
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_rule_management.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# RULE LISTING AND DISPLAY TESTS
# ============================================================================

test_list_local_mode_only_glyphs() {
    # Setup: Local mode only with one rule
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: List should show local and uninstalled glyphs only
    output=$(cmd_list)
    
    # Expected: Shows ◐ for installed local rule, ○ for others
    echo "$output" | grep -q "$LOCAL_GLYPH.*rule1" || fail "Should show local glyph for rule1"
    echo "$output" | grep -q "$UNINSTALLED_GLYPH.*rule2" || fail "Should show uninstalled glyph for rule2"
    if echo "$output" | grep -q "$COMMITTED_GLYPH"; then
        fail "Should not show committed glyph in local-only mode"
    fi
}

test_list_commit_mode_only_glyphs() {
    # Setup: Commit mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    cmd_add_rule "rule1.mdc" --commit
    
    output=$(cmd_list)
    
    # Expected: Shows ● for committed rule, ○ for others  
    echo "$output" | grep -q "$COMMITTED_GLYPH.*rule1" || fail "Should show committed glyph for rule1"
    echo "$output" | grep -q "$UNINSTALLED_GLYPH.*rule2" || fail "Should show uninstalled glyph for rule2"
    if echo "$output" | grep -q "$LOCAL_GLYPH"; then
        fail "Should not show local glyph in commit-only mode"
    fi
}

test_list_dual_mode_all_glyphs() {
    # Setup: Both modes with different rules
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit  # Lazy init commit mode
    
    output=$(cmd_list)
    
    # Expected: Shows all three glyphs
    echo "$output" | grep -q "$LOCAL_GLYPH.*rule1" || fail "Should show local glyph for rule1"
    echo "$output" | grep -q "$COMMITTED_GLYPH.*rule2" || fail "Should show committed glyph for rule2"
    echo "$output" | grep -q "$UNINSTALLED_GLYPH.*rule3" || fail "Should show uninstalled glyph for rule3"
}

test_list_progressive_display_no_modes() {
    # Setup: No modes initialized
    assert_no_modes_exist
    
    # Test: List should error when no modes exist
    output=$(cmd_list 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should error about no configuration
    echo "$output" | grep -q "No ai-rizz configuration found" || fail "Should error about no configuration"
}

test_list_with_custom_target_dir() {
    # Setup: Custom target directory
    custom_dir=".custom/rules"
    cmd_init "$SOURCE_REPO" -d "$custom_dir" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: List should work with custom directory
    output=$(cmd_list)
    
    # Expected: Should show rule with local glyph
    echo "$output" | grep -q "$LOCAL_GLYPH.*rule1" || fail "Should show local glyph for rule1"
}

# ============================================================================
# RULE REMOVAL TESTS
# ============================================================================

test_remove_rule_auto_detects_mode() {
    # Setup: Rule in local mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: Remove without mode flag, then sync to ensure file removal
    cmd_remove_rule "rule1.mdc"
    cmd_sync
    
    # Expected: Auto-detects and removes from local mode
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
}

test_remove_rule_from_correct_mode() {
    # Setup: Different rules in different modes
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Remove from each mode, then sync to ensure file removal
    cmd_remove_rule "rule1.mdc"
    cmd_remove_rule "rule2.mdc"
    cmd_sync
    
    # Expected: Each removed from correct mode
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
}

test_remove_nonexistent_rule_graceful() {
    # Setup: Local mode only
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    
    # Test: Remove nonexistent rule
    output=$(cmd_remove_rule "nonexistent.mdc" 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should handle gracefully
    echo "$output" | grep -q "not found\|warning" || fail "Should warn about missing rule"
}

test_remove_rule_from_dual_mode() {
    # Setup: Same rule in both modes (edge case)
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Manually add to commit mode to test conflict
    cmd_add_rule "rule1.mdc" --commit  # Should migrate, but test edge case
    
    # Test: Remove should remove from commit mode (higher priority), then sync
    cmd_remove_rule "rule1.mdc"
    cmd_sync
    
    # Expected: Should remove from commit mode
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
}

test_remove_updates_manifests() {
    # Setup: Rules in both modes
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Remove rules and verify manifest updates
    cmd_remove_rule "rule1.mdc"
    cmd_remove_rule "rule2.mdc"
    
    # Expected: Manifests should be updated
    local_manifest_content=$(cat "$LOCAL_MANIFEST_FILE")
    if echo "$local_manifest_content" | grep -q "rule1.mdc"; then
        fail "Rule1 should be removed from local manifest"
    fi
    
    commit_manifest_content=$(cat "$COMMIT_MANIFEST_FILE")
    if echo "$commit_manifest_content" | grep -q "rule2.mdc"; then
        fail "Rule2 should be removed from commit manifest"
    fi
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 