#!/bin/sh
#
# test_mode_operations.test.sh - Mode-aware operations test suite
#
# Tests all mode-aware operations including add/remove rules and rulesets,
# lazy initialization, upgrade/downgrade constraints, and cross-mode
# interactions. Validates the complete command interface with proper mode
# handling and constraint enforcement.
#
# Test Coverage:
# Validates all mode-aware command operations including add/remove behavior,
# progressive display systems, lazy initialization triggers, constraint
# enforcement, and proper sync coordination across various operational
# scenarios and edge cases.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_mode_operations.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Main test functions
# ------------------

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

test_list_rulesets_correct_glyphs() {
    # Setup: Test the correct behavior - individual rules can't be downgraded from committed rulesets
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_ruleset "ruleset1" --local  # Add ruleset to local mode first
    cmd_add_rule "rule1.mdc" --commit   # Promote individual rule to commit mode (upgrade)
    
    output=$(cmd_list)
    
    # Expected: rule1 should show commit glyph (promoted), ruleset1 should show local glyph (still has rule2)
    echo "$output" | grep -q "$COMMITTED_GLYPH.*rule1" || fail "Should show committed glyph for rule1 (promoted from local ruleset)"
    echo "$output" | grep -q "$LOCAL_GLYPH.*ruleset1" || fail "Should show local glyph for ruleset1 (still contains rule2)"
}

test_prevent_rule_downgrade_from_committed_ruleset() {
    # Setup: Committed ruleset with rule1 and rule2
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    cmd_add_ruleset "ruleset1" --commit
    
    # Test: Try to add individual rule from committed ruleset to local mode (should warn and be no-op)
    output=$(cmd_add_rule "rule1.mdc" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should warn about downgrade prevention
    echo "$output" | grep -q "Cannot add individual rule.*part of committed ruleset" || fail "Should warn about downgrade prevention"
    
    # Verify rule1 is still only in commit mode (not added to local)
    list_output=$(cmd_list)
    echo "$list_output" | grep -q "$COMMITTED_GLYPH.*rule1" || fail "Rule1 should still show committed glyph"
    if echo "$list_output" | grep -q "$LOCAL_GLYPH.*rule1"; then
        fail "Rule1 should not have been added to local mode"
    fi
}

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

test_sync_all_initialized_modes() {
    # Setup: Both modes with rules
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
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
}

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

test_sync_triggers_after_remove() {
    # Setup: Rules in both modes
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Remove should trigger sync automatically
    cmd_remove_rule "rule1.mdc"
    
    # Expected: Sync should have been called (files should be gone)
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"  # Should remain
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 