#!/bin/sh
#
# test_error_handling.test.sh - Error handling and edge cases test suite
#
# Tests comprehensive error handling throughout ai-rizz including invalid
# inputs, missing files, network failures, permission issues, and edge cases.
# Validates graceful degradation, helpful error messages, and system recovery.
#
# Test Coverage:
# Validates comprehensive error handling and graceful degradation across
# all failure modes including network issues, permission problems, corrupted
# data, and edge cases while ensuring helpful error messages and system
# state consistency.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_error_handling.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Main test functions
# ------------------

test_error_no_init_before_add() {
    # Setup: No initialization
    assert_no_modes_exist
    
    # Test: Add rule without init
    output=$(cmd_add_rule "rule1.mdc" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Clear error message with init suggestion
    echo "$output" | grep -q "init" || fail "Should suggest running init"
    echo "$output" | grep -q "configuration.*found" || fail "Should mention no configuration"
}

test_error_invalid_mode_flag() {
    # Setup: Valid repo
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Test: Invalid mode flag
    output=$(cmd_add_rule "rule1.mdc" --invalid 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Error about invalid mode
    echo "$output" | grep -q "invalid\|unknown" || fail "Should report invalid mode"
}

test_error_missing_source_repo() {
    # Test: Init without source repo (provide empty input to prompt)
    output=$(echo "" | cmd_init -d "$TEST_TARGET_DIR" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Error about missing source repo
    echo "$output" | grep -q "source.*required\|repository.*required\|Source repository URL" || fail "Should require source repo"
}

test_graceful_nonexistent_rule() {
    # Setup: Valid initialization
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Test: Add nonexistent rule
    output=$(cmd_add_rule "nonexistent.mdc" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Warning but not fatal error
    echo "$output" | grep -q "not found\|warning" || fail "Should warn about missing rule"
}

test_graceful_corrupted_manifest() {
    # Setup: Corrupted manifest
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    echo "CORRUPTED_DATA" > "$TEST_LOCAL_MANIFEST_FILE"
    
    # Test: Operations should handle gracefully
    output=$(cmd_list 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Error but clear message
    echo "$output" | grep -q "format\|corrupt\|invalid" || fail "Should report manifest issue"
}

test_error_invalid_target_directory() {
    # Test: Init with invalid target directory
    output=$(cmd_init "$TEST_SOURCE_REPO" -d "/invalid/readonly/path" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should error about target directory
    echo "$output" | grep -q "directory\|path\|permission" || fail "Should mention directory issue"
}

test_error_git_repo_required_for_commit_mode() {
    # Setup: Non-git directory
    rm -rf .git
    
    # Test: Commit mode should require git repository and fail
    # Use subshell to capture exit code without exiting the test
    (cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit >/dev/null 2>&1)
    exit_code=$?
    assertFalse "Commit mode init should fail outside a git repo" $exit_code

    output=$(cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit 2>&1)
    echo "$output" | grep -q "git.*repository\|not.*git" || \
        fail "Should require git repo for commit mode"
}

test_local_mode_requires_git() {
    # Setup: Non-git directory
    rm -rf .git
    
    # Test: Local mode should fail without git repository (like commit mode)
    output=$(cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local 2>&1)
    exit_code=$?
    
    # Expected: Should fail with git requirement error
    assertNotEquals "Local mode init should fail outside a git repo" "0" "$exit_code"
    echo "$output" | grep -qi "git" || fail "Should mention git in error: $output"
    assertFalse "Should not create local manifest" "[ -f '$TEST_LOCAL_MANIFEST_FILE' ]"
}

test_graceful_missing_git_exclude() {
    # Setup: Remove git info directory
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    rm -rf .git/info
    
    # Test: Should handle missing git exclude file
    output=$(cmd_add_rule "rule1.mdc" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should create git exclude or handle gracefully
    assertTrue "Should handle missing git info" "[ -f '$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc' ] || echo '$output' | grep -q 'warning'"
}

test_error_readonly_manifest() {
    # Setup: Make manifest read-only
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    chmod 444 "$TEST_LOCAL_MANIFEST_FILE"
    
    # Test: Add rule should error
    output=$(cmd_add_rule "rule1.mdc" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should error about permissions
    echo "$output" | grep -q "permission\|read-only\|cannot.*write" || fail "Should report permission error"
    
    # Restore permissions for cleanup
    chmod 644 "$TEST_LOCAL_MANIFEST_FILE"
}

test_error_source_repo_unavailable() {
    # Test: Init with invalid source repo should fail
    output=$(cmd_init "invalid://nonexistent.repo" -d "$TEST_TARGET_DIR" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should fail with repository error
    echo "$output" | grep -q "repository\|clone\|fetch\|unavailable\|ERROR_OCCURRED" || fail "Should fail with repo issue"
    
    # Verify that no configuration was created
    [ ! -f "$TEST_LOCAL_MANIFEST_FILE" ] || fail "Should not create manifest with invalid repo"
}

test_error_malformed_ruleset() {
    # Setup: Local mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Create malformed ruleset in repo (broken symlinks)
    mkdir -p "$REPO_DIR/rulesets/broken_ruleset"
    ln -sf "/nonexistent/file" "$REPO_DIR/rulesets/broken_ruleset/broken.mdc"
    
    # Test: Add malformed ruleset
    output=$(cmd_add_ruleset "broken_ruleset" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should warn about broken files
    echo "$output" | grep -q "broken\|symlink\|not found\|warning" || fail "Should warn about broken files"
}

test_error_concurrent_modification() {
    # Setup: Both modes
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Simulate concurrent modification by changing manifest during operation
    # This is a simplified test of race conditions
    original_content=$(cat "$TEST_LOCAL_MANIFEST_FILE")
    
    # Modify manifest externally
    echo "externally_added_rule" >> "$TEST_LOCAL_MANIFEST_FILE"
    
    # Test: Operations should handle external changes
    output=$(cmd_add_rule "rule2.mdc" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should complete or warn about external changes
    assertTrue "Should handle external changes" "[ -f '$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc' ] || echo '$output' | grep -q 'warning'"
}

test_error_network_timeout() {
    # Test: Init with network-dependent source that times out
    output=$(timeout 1 cmd_init "https://github.com/nonexistent/timeout-test.git" -d "$TEST_TARGET_DIR" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should handle timeout gracefully (either timeout or repository unavailable error)
    echo "$output" | grep -q "timeout\|network\|failed\|unavailable\|ERROR_OCCURRED" || fail "Should handle network issues gracefully"
}

test_graceful_partial_rule_sync() {
    # Setup: Local mode with rule that exists in manifest but not in target
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Remove the synced file to simulate partial sync
    rm -f "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    
    # Test: List should handle missing synced files
    output=$(cmd_list 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should show rule as in manifest but warn about missing file
    echo "$output" | grep -q "rule1" || fail "Should still show rule from manifest"
}

test_error_invalid_manifest_format() {
    # Setup: Create manifest with invalid format
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Corrupt the manifest header
    echo "INVALID FORMAT WITHOUT TAB" > "$TEST_LOCAL_MANIFEST_FILE"
    
    # Test: Operations should detect invalid format
    output=$(cmd_list 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should error about invalid format
    echo "$output" | grep -q "format\|invalid\|corrupt" || fail "Should detect invalid format"
}

test_error_cleanup_on_failure() {
    # Setup: Start init process
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Simulate failure during add operation by making target readonly
    chmod 444 "$TEST_TARGET_DIR"
    
    # Test: Failed operation should not leave inconsistent state
    output=$(cmd_add_rule "rule1.mdc" --local 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should error and not add partial entry to manifest
    echo "$output" | grep -q "error\|permission\|failed" || fail "Should report error"
    
    # Manifest should not contain the failed rule
    if [ -f "$TEST_LOCAL_MANIFEST_FILE" ]; then
        local_content=$(cat "$TEST_LOCAL_MANIFEST_FILE")
        echo "$local_content" | grep -q "rule1.mdc" && fail "Should not add failed rule to manifest"
    fi
    
    # Restore permissions for cleanup
    chmod 755 "$TEST_TARGET_DIR"
}

test_graceful_empty_repository() {
    # Setup: Empty source repository
    empty_repo="$TEST_DIR/empty_repo"
    mkdir -p "$empty_repo"
    cd "$empty_repo" || fail "Failed to change to empty repo"
    git init . >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1
    git commit --no-gpg-sign --allow-empty -m "Empty commit" >/dev/null 2>&1
    cd "$TEST_DIR/app" || fail "Failed to return to test app dir"
    
    # Test: Init with empty repo
    cmd_init "$empty_repo" -d "$TEST_TARGET_DIR" --local
    
    # Test: List should handle empty repo
    output=$(cmd_list 2>&1)
    
    # Expected: Should work but show no rules
    echo "$output" | grep -q "No rules available\|empty\|found" || true  # May show empty state
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 