#!/bin/sh
#
# test_no_git_local_mode.test.sh - Test local mode without git repository
#
# Tests that ai-rizz can operate in local mode without requiring a git repository,
# while still requiring git for commit mode. Validates graceful handling of
# missing .git directory and git exclude operations.
#
# Test Coverage:
# - Local mode initialization without git repository
# - Commit mode still requires git repository
# - Git exclude operations handle missing .git gracefully
# - All local mode operations work without git
# - Mode transitions with/without git
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_no_git_local_mode.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# NO-GIT LOCAL MODE TESTS
# ============================================================================

test_local_mode_without_git_repo() {
    # Setup: Remove git repository
    rm -rf .git
    assertFalse "Should not have git repo" "[ -d '.git' ]"
    
    # Test: Initialize local mode without git
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Expected: Should succeed and create local mode
    assert_local_mode_exists
    assert_file_not_exists "$TEST_COMMIT_MANIFEST_FILE"
    
    # Verify mode detection works
    assertTrue "Should detect local mode" "[ \"$(is_mode_active local)\" = \"true\" ]"
    assertFalse "Should not detect commit mode" "[ \"$(is_mode_active commit)\" = \"true\" ]"
}

test_commit_mode_requires_git_repo() {
    # Setup: Remove git repository  
    rm -rf .git
    assertFalse "Should not have git repo" "[ -d '.git' ]"
    
    # Test: Try to initialize commit mode without git
    output=$(cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should fail with git requirement error
    echo "$output" | grep -q "git.*repository\|not.*git\|ERROR_OCCURRED" || fail "Should require git repo for commit mode"
    
    # Verify no commit mode created
    assert_file_not_exists "$TEST_COMMIT_MANIFEST_FILE"
    assertFalse "Should not detect commit mode" "[ \"$(is_mode_active commit)\" = \"true\" ]"
}

test_local_add_rule_without_git() {
    # Setup: Local mode without git
    rm -rf .git
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Test: Add rule in local mode
    cmd_add_rule "rule1.mdc" --local
    
    # Expected: Should work and deploy rule
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    
    # Verify manifest updated
    local_entries=$(tail -n +2 "$TEST_LOCAL_MANIFEST_FILE")
    echo "$local_entries" | grep -q "rules/rule1.mdc" || fail "Rule should be in manifest"
}

test_local_add_ruleset_without_git() {
    # Setup: Local mode without git
    rm -rf .git
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Test: Add ruleset in local mode
    cmd_add_ruleset "ruleset1" --local
    
    # Expected: Should work and deploy ruleset files
    assertTrue "Ruleset should be deployed" "[ -d '$TEST_TARGET_DIR/$TEST_LOCAL_DIR' ] && ls '$TEST_TARGET_DIR/$TEST_LOCAL_DIR'/*.mdc >/dev/null 2>&1"
    
    # Verify manifest updated
    local_entries=$(tail -n +2 "$TEST_LOCAL_MANIFEST_FILE")
    echo "$local_entries" | grep -q "rulesets/ruleset1" || fail "Ruleset should be in manifest"
}

test_local_sync_without_git() {
    # Setup: Local mode without git
    rm -rf .git
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: Sync without git
    cmd_sync
    
    # Expected: Should work and maintain rule deployment
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
}

test_local_list_without_git() {
    # Setup: Local mode without git
    rm -rf .git
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: List rules without git
    output=$(cmd_list 2>&1)
    
    # Expected: Should work and show rules
    echo "$output" | grep -q "rule1.mdc" || fail "Should list added rule"
    echo "$output" | grep -q "Available rules" || fail "Should show rules section"
}

test_local_remove_rule_without_git() {
    # Setup: Local mode without git with rule
    rm -rf .git
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    
    # Test: Remove rule without git
    cmd_remove_rule "rule1.mdc"
    
    # Expected: Should work and remove rule
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    
    # Verify manifest updated
    local_entries=$(tail -n +2 "$TEST_LOCAL_MANIFEST_FILE" || true)
    if [ -n "$local_entries" ]; then
        echo "$local_entries" | grep -q "rule1.mdc" && fail "Rule should be removed from manifest"
    fi
}

test_local_deinit_without_git() {
    # Setup: Local mode without git
    rm -rf .git
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    assert_local_mode_exists
    
    # Test: Deinitialize local mode without git
    cmd_deinit --local -y
    
    # Expected: Should work and remove local mode
    assert_file_not_exists "$TEST_LOCAL_MANIFEST_FILE"
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
    assertFalse "Should not detect local mode" "[ \"$(is_mode_active local)\" = \"true\" ]"
}

# ============================================================================
# GIT EXCLUDE GRACEFUL HANDLING TESTS
# ============================================================================

test_git_exclude_operations_without_git() {
    # Setup: No git repository
    rm -rf .git
    
    # Test: Git exclude operations should not fail
    # These functions should gracefully handle missing .git
    setup_local_mode_excludes "$TEST_TARGET_DIR" || fail "setup_local_mode_excludes should not fail without git"
    remove_local_mode_excludes "$TEST_TARGET_DIR" || fail "remove_local_mode_excludes should not fail without git"
    validate_git_exclude_state "$TEST_TARGET_DIR" || fail "validate_git_exclude_state should not fail without git"
}

test_update_git_exclude_without_git() {
    # Setup: No git repository
    rm -rf .git
    
    # Test: update_git_exclude should gracefully handle missing .git
    update_git_exclude "test-file" "add" || fail "update_git_exclude add should not fail without git"
    update_git_exclude "test-file" "remove" || fail "update_git_exclude remove should not fail without git"
}

# ============================================================================
# MODE TRANSITION TESTS
# ============================================================================

test_add_commit_mode_after_local_without_git() {
    # Setup: Local mode without git
    rm -rf .git
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    assert_local_mode_exists
    
    # Setup git after local mode exists
    git init . >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1  
    git config user.name "Test User" >/dev/null 2>&1
    assertTrue "Should have git repo" "[ -d '.git' ]"
    
    # Test: Add commit mode after local mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    
    # Expected: Should work and create dual mode
    assert_local_mode_exists
    assert_commit_mode_exists
    assertTrue "Should detect both modes" "[ \"$(is_mode_active local)\" = \"true\" ] && [ \"$(is_mode_active commit)\" = \"true\" ]"
}

test_lazy_init_commit_from_local_without_git() {
    # Setup: Local mode without git
    rm -rf .git
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Setup git
    git init . >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1
    
    # Test: Try to add rule to commit mode (lazy init)
    cmd_add_rule "rule2.mdc" --commit
    
    # Expected: Should create commit mode and add rule
    assert_commit_mode_exists
    assert_file_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule2.mdc"
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 