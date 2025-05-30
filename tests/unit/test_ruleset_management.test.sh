#!/bin/sh
#
# test_ruleset_management.test.sh - Ruleset management and constraints test suite
#
# Tests all operations related to ruleset management including add/remove behavior,
# upgrade/downgrade constraints between individual rules and rulesets, conflict
# resolution, and proper display of ruleset status. Validates ruleset-specific
# command interface with constraint enforcement and mode handling.
#
# Test Coverage:
# - Ruleset add/remove operations
# - Upgrade constraints (individual → ruleset always allowed)
# - Downgrade constraints (committed ruleset → individual blocked)
# - Ruleset listing and status display
# - Cross-mode ruleset behavior
# - Rule promotion from rulesets
# - Constraint violation error handling
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_ruleset_management.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# RULESET LISTING AND DISPLAY TESTS
# ============================================================================

test_list_rulesets_correct_glyphs() {
    # Setup: Test the correct behavior - individual rules can't be downgraded from committed rulesets
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_ruleset "ruleset1" --local  # Add ruleset to local mode first
    cmd_add_rule "rule1.mdc" --commit   # Promote individual rule to commit mode (upgrade)
    
    output=$(cmd_list)
    
    # Expected: rule1 should show commit glyph (promoted), ruleset1 should show local glyph (still has rule2)
    echo "$output" | grep -q "$COMMITTED_GLYPH.*rule1" || fail "Should show committed glyph for rule1 (promoted from local ruleset)"
    echo "$output" | grep -q "$LOCAL_GLYPH.*ruleset1" || fail "Should show local glyph for ruleset1 (still contains rule2)"
}

# ============================================================================
# UPGRADE/DOWNGRADE CONSTRAINT TESTS
# ============================================================================

test_prevent_rule_downgrade_from_committed_ruleset() {
    # Setup: Committed ruleset with rule1 and rule2
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
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

test_allow_rule_upgrade_to_committed_ruleset() {
    # Setup: Individual rule in local mode  
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: Add ruleset containing that rule to commit mode (upgrade should be allowed)
    cmd_add_ruleset "ruleset1" --commit
    
    # Expected: Rule should be promoted to committed ruleset, local individual entry removed
    list_output=$(cmd_list)
    echo "$list_output" | grep -q "$COMMITTED_GLYPH.*ruleset1" || fail "Ruleset1 should show committed glyph"
    
    # The individual rule entry should be subsumed by the ruleset
    if echo "$list_output" | grep -q "$LOCAL_GLYPH.*rule1"; then
        fail "Individual rule1 should be subsumed by committed ruleset"
    fi
}

test_allow_rule_upgrade_to_local_ruleset() {
    # Setup: Individual rule in commit mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Add ruleset containing that rule to local mode (upgrade should be allowed)
    cmd_add_ruleset "ruleset1" --local
    
    # Expected: Rule should be available in both individual (commit) and ruleset (local) forms
    list_output=$(cmd_list)
    echo "$list_output" | grep -q "$COMMITTED_GLYPH.*rule1" || fail "Rule1 should still show committed glyph"
    echo "$list_output" | grep -q "$LOCAL_GLYPH.*ruleset1" || fail "Ruleset1 should show local glyph"
}

test_prevent_downgrade_from_local_ruleset() {
    # Setup: Local ruleset with rule1 and rule2
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_ruleset "ruleset1" --local
    
    # Test: Try to add individual rule from local ruleset to commit mode (should be allowed - this is upgrade)
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Should succeed (this is an upgrade, not downgrade)
    list_output=$(cmd_list)
    echo "$list_output" | grep -q "$COMMITTED_GLYPH.*rule1" || fail "Rule1 should show committed glyph (upgraded)"
    echo "$list_output" | grep -q "$LOCAL_GLYPH.*ruleset1" || fail "Ruleset1 should still show local glyph"
}

# ============================================================================
# RULESET CROSS-MODE BEHAVIOR TESTS
# ============================================================================

test_ruleset_mode_migration() {
    # Setup: Ruleset in local mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_ruleset "ruleset1" --local
    
    # Verify initial state
    list_output=$(cmd_list)
    echo "$list_output" | grep -q "$LOCAL_GLYPH.*ruleset1" || fail "Ruleset1 should initially show local glyph"
    
    # Test: Move ruleset to commit mode
    cmd_add_ruleset "ruleset1" --commit
    
    # Expected: Ruleset should move to commit mode
    list_output=$(cmd_list)
    echo "$list_output" | grep -q "$COMMITTED_GLYPH.*ruleset1" || fail "Ruleset1 should show committed glyph after migration"
    
    # Local mode should no longer have the ruleset
    if echo "$list_output" | grep -q "$LOCAL_GLYPH.*ruleset1"; then
        fail "Ruleset1 should not show local glyph after migration to commit"
    fi
}

test_ruleset_removes_all_constituent_rules() {
    # Setup: Ruleset in local mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_ruleset "ruleset1" --local
    
    # Verify files exist
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc"
    
    # Test: Remove ruleset
    cmd_remove_ruleset "ruleset1"
    cmd_sync
    
    # Expected: All constituent rule files should be removed
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc"
}

test_ruleset_add_with_existing_individual_rules() {
    # Setup: Individual rules already exist
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --local
    
    # Test: Add ruleset containing those rules
    cmd_add_ruleset "ruleset1" --local
    
    # Expected: Individual rule entries should be consolidated into ruleset
    list_output=$(cmd_list)
    echo "$list_output" | grep -q "$LOCAL_GLYPH.*ruleset1" || fail "Ruleset1 should show local glyph"
    
    # Individual entries should be removed in favor of the ruleset
    if echo "$list_output" | grep -q "rules/rule1.mdc"; then
        fail "Individual rule1 entry should be consolidated into ruleset"
    fi
    if echo "$list_output" | grep -q "rules/rule2.mdc"; then
        fail "Individual rule2 entry should be consolidated into ruleset" 
    fi
}

# ============================================================================
# ERROR HANDLING TESTS
# ============================================================================

test_remove_nonexistent_ruleset_graceful() {
    # Setup: Local mode only
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Test: Remove nonexistent ruleset
    output=$(cmd_remove_ruleset "nonexistent" 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should handle gracefully
    echo "$output" | grep -q "not found\|warning" || fail "Should warn about missing ruleset"
}

test_add_nonexistent_ruleset_warning() {
    # Setup: Local mode only
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Test: Add nonexistent ruleset
    output=$(cmd_add_ruleset "nonexistent" --local 2>&1)
    exit_code=$?
    
    # Expected: Should succeed but show warning
    assertEquals "Add nonexistent ruleset should succeed" 0 $exit_code
    echo "$output" | grep -q "Warning\|not found" || fail "Should warn about nonexistent ruleset"
    
    # Should not create any files or manifest entries
    if [ -f "$TEST_LOCAL_MANIFEST_FILE" ]; then
        local_content=$(cat "$TEST_LOCAL_MANIFEST_FILE")
        if echo "$local_content" | grep -q "nonexistent"; then
            fail "Should not add nonexistent ruleset to manifest"
        fi
    fi
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 