#!/bin/sh
#
# test_cli_deinit.test.sh - Integration tests for ai-rizz deinit command
#
# Tests the public CLI interface for the deinit command by executing ai-rizz
# directly and verifying the resulting system state. Validates mode-selective
# removal behavior, confirmation prompt handling, cleanup operations, git
# exclude management, and error handling for various deinitialization
# scenarios including single-mode and dual-mode repositories.
#
# Dependencies: shunit2, integration test utilities
# Usage: sh test_cli_deinit.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Integration test setup and teardown
setUp() {
    setup_integration_test
}

tearDown() {
    teardown_integration_test
}

# Test: ai-rizz deinit --local
# Expected: Removes only local mode, leaves commit mode intact
test_deinit_local_mode_only() {
    # Initialize dual mode with rules
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    run_ai_rizz add rule rule1 --local
    run_ai_rizz add rule rule2 --commit
    assertEquals "Setup should succeed" 0 $?
    
    # Verify both modes exist
    assertTrue "Local manifest should exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Commit manifest should exist" "[ -f 'ai-rizz.skbd' ]"
    assertTrue "Local directory should exist" "[ -d '.cursor/rules/local' ]"
    assertTrue "Shared directory should exist" "[ -d '.cursor/rules/shared' ]"
    
    # Deinit local mode only
    run_ai_rizz deinit --local -y
    assertEquals "Deinit local should succeed" 0 $?
    
    # Verify local mode removed
    assertFalse "Local manifest should be removed" "[ -f 'ai-rizz.local.skbd' ]"
    assertFalse "Local directory should be removed" "[ -d '.cursor/rules/local' ]"
    
    # Verify commit mode intact
    assertTrue "Commit manifest should remain" "[ -f 'ai-rizz.skbd' ]"
    assertTrue "Shared directory should remain" "[ -d '.cursor/rules/shared' ]"
    assert_rule_deployed ".cursor/rules/shared" "rule2"
    
    # Verify git excludes cleaned up
    assert_git_tracks "ai-rizz.local.skbd"
    assert_git_tracks ".cursor/rules/local"
}

# Test: ai-rizz deinit --commit
# Expected: Removes only commit mode, leaves local mode intact
test_deinit_commit_mode_only() {
    # Initialize dual mode with rules
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    run_ai_rizz add rule rule1 --local
    run_ai_rizz add rule rule2 --commit
    assertEquals "Setup should succeed" 0 $?
    
    # Verify both modes exist
    assertTrue "Local manifest should exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Commit manifest should exist" "[ -f 'ai-rizz.skbd' ]"
    assertTrue "Local directory should exist" "[ -d '.cursor/rules/local' ]"
    assertTrue "Shared directory should exist" "[ -d '.cursor/rules/shared' ]"
    
    # Deinit commit mode only
    run_ai_rizz deinit --commit -y
    assertEquals "Deinit commit should succeed" 0 $?
    
    # Verify commit mode removed
    assertFalse "Commit manifest should be removed" "[ -f 'ai-rizz.skbd' ]"
    assertFalse "Shared directory should be removed" "[ -d '.cursor/rules/shared' ]"
    
    # Verify local mode intact
    assertTrue "Local manifest should remain" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Local directory should remain" "[ -d '.cursor/rules/local' ]"
    assert_rule_deployed ".cursor/rules/local" "rule1"
    
    # Verify git excludes still correct for local mode
    assert_git_excludes "ai-rizz.local.skbd"
    assert_git_excludes ".cursor/rules/local"
}

# Test: ai-rizz deinit --all
# Expected: Removes both modes completely
test_deinit_all_modes() {
    # Initialize dual mode with rules
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    run_ai_rizz add rule rule1 --local
    run_ai_rizz add rule rule2 --commit
    assertEquals "Setup should succeed" 0 $?
    
    # Verify both modes exist
    assertTrue "Local manifest should exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Commit manifest should exist" "[ -f 'ai-rizz.skbd' ]"
    assertTrue "Local directory should exist" "[ -d '.cursor/rules/local' ]"
    assertTrue "Shared directory should exist" "[ -d '.cursor/rules/shared' ]"
    
    # Deinit all modes
    run_ai_rizz deinit --all -y
    assertEquals "Deinit all should succeed" 0 $?
    
    # Verify everything removed
    assertFalse "Local manifest should be removed" "[ -f 'ai-rizz.local.skbd' ]"
    assertFalse "Commit manifest should be removed" "[ -f 'ai-rizz.skbd' ]"
    assertFalse "Local directory should be removed" "[ -d '.cursor/rules/local' ]"
    assertFalse "Shared directory should be removed" "[ -d '.cursor/rules/shared' ]"
    
    # Verify git excludes cleaned up
    assert_git_tracks "ai-rizz.local.skbd"
    assert_git_tracks ".cursor/rules/local"
}

# Test: ai-rizz deinit (no flags)
# Expected: Should prompt for mode selection or show error
test_deinit_requires_mode_selection() {
    # Initialize dual mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    assertEquals "Setup should succeed" 0 $?
    
    # Try deinit without mode flag, provide empty input to prompt
    local output
    output=$(echo "" | run_ai_rizz deinit 2>&1 || echo "DEINIT_FAILED")
    
    # Should either show mode selection prompt or require mode flag
    if echo "$output" | grep -q "DEINIT_FAILED"; then
        # Command failed - should show helpful error about mode selection
        assert_output_contains "$output" "mode\|local\|commit\|all"
    else
        # Command showed prompt - should contain mode selection text
        assert_output_contains "$output" "mode\|local\|commit\|all\|choose\|select"
    fi
}

# Test: ai-rizz deinit --local (with confirmation prompt)
# Expected: Should prompt for confirmation when -y not provided
test_deinit_requires_confirmation() {
    # Initialize local mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz add rule rule1 --local
    assertEquals "Setup should succeed" 0 $?
    
    # Try deinit without -y flag, provide "n" to decline
    local output
    output=$(echo "n" | run_ai_rizz deinit --local 2>&1 || echo "DEINIT_CANCELLED")
    
    # Should either show confirmation prompt or require -y flag
    if echo "$output" | grep -q "DEINIT_CANCELLED"; then
        # Command was cancelled or failed - files should remain
        assertTrue "Local manifest should remain after cancellation" "[ -f 'ai-rizz.local.skbd' ]"
        assertTrue "Local directory should remain after cancellation" "[ -d '.cursor/rules/local' ]"
    else
        # Command showed prompt - should contain confirmation text
        assert_output_contains "$output" "confirm\|sure\|delete\|remove\|yes\|no"
    fi
}

# Test: ai-rizz deinit --local -y
# Expected: Should skip confirmation prompt with -y flag
test_deinit_with_yes_flag_skips_confirmation() {
    # Initialize local mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz add rule rule1 --local
    assertEquals "Setup should succeed" 0 $?
    
    # Verify initial state
    assertTrue "Local manifest should exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Local directory should exist" "[ -d '.cursor/rules/local' ]"
    
    # Deinit with -y flag (should not prompt)
    local output
    output=$(run_ai_rizz deinit --local -y 2>&1)
    assertEquals "Deinit with -y should succeed" 0 $?
    
    # Should not contain confirmation prompts
    assert_output_not_contains "$output" "confirm\|sure\|yes\|no"
    
    # Verify removal completed
    assertFalse "Local manifest should be removed" "[ -f 'ai-rizz.local.skbd' ]"
    assertFalse "Local directory should be removed" "[ -d '.cursor/rules/local' ]"
}

# Test: ai-rizz deinit on single mode repository
# Expected: Should work correctly with only one mode initialized
test_deinit_single_mode_repository() {
    # Initialize only local mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz add rule rule1 --local
    assertEquals "Setup should succeed" 0 $?
    
    # Verify only local mode exists
    assertTrue "Local manifest should exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertFalse "Commit manifest should not exist" "[ -f 'ai-rizz.skbd' ]"
    
    # Deinit local mode
    run_ai_rizz deinit --local -y
    assertEquals "Deinit should succeed" 0 $?
    
    # Verify complete removal
    assertFalse "Local manifest should be removed" "[ -f 'ai-rizz.local.skbd' ]"
    assertFalse "Local directory should be removed" "[ -d '.cursor/rules/local' ]"
    
    # Verify git excludes cleaned up
    assert_git_tracks "ai-rizz.local.skbd"
    assert_git_tracks ".cursor/rules/local"
}

# Test: ai-rizz deinit --commit on local-only repository
# Expected: Should handle gracefully when target mode doesn't exist
test_deinit_nonexistent_mode() {
    # Initialize only local mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "Setup should succeed" 0 $?
    
    # Try to deinit commit mode (which doesn't exist)
    local output
    output=$(run_ai_rizz deinit --commit -y 2>&1)
    local exit_code=$?
    
    # Should handle gracefully (either succeed or show helpful message)
    if [ $exit_code -ne 0 ]; then
        assert_output_contains "$output" "not found\|not initialized\|no commit mode"
    fi
    
    # Local mode should remain untouched
    assertTrue "Local manifest should remain" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Local directory should remain" "[ -d '.cursor/rules/local' ]"
}

# Test: ai-rizz deinit without initialization
# Expected: Should show appropriate error message
test_deinit_without_initialization() {
    # Try to deinit without any initialization
    local output
    output=$(run_ai_rizz deinit --local -y 2>&1 || echo "DEINIT_FAILED")
    
    # Should fail with helpful error
    assert_output_contains "$output" "DEINIT_FAILED\|No ai-rizz configuration\|not initialized"
}

# Test: ai-rizz deinit preserves parent directory structure
# Expected: Should only remove ai-rizz files, not parent directories
test_deinit_preserves_parent_directories() {
    # Initialize with custom nested directory
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d custom/nested/rules --local
    assertEquals "Setup should succeed" 0 $?
    
    # Verify structure created
    assertTrue "Custom directory should exist" "[ -d 'custom/nested/rules/local' ]"
    
    # Create additional file in parent directory
    echo "other content" > custom/nested/other_file.txt
    
    # Deinit
    run_ai_rizz deinit --local -y
    assertEquals "Deinit should succeed" 0 $?
    
    # Verify ai-rizz files removed but parent structure preserved
    assertFalse "Local directory should be removed" "[ -d 'custom/nested/rules/local' ]"
    assertTrue "Parent directory should remain" "[ -d 'custom/nested' ]"
    assertTrue "Other files should remain" "[ -f 'custom/nested/other_file.txt' ]"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 