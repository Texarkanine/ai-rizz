#!/bin/sh
#
# test_global_only_context.test.sh - Global-only operation test suite
#
# Tests that ai-rizz can operate in global-only mode when running outside
# of a git repository. This enables user-wide rule management without
# requiring a local git repo.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_global_only_context.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# TEST SETUP
# ============================================================================

# Override setUp to NOT require git repo
setUp() {
    # Unset all AI_RIZZ_* environment variables to prevent host pollution
    unset AI_RIZZ_MANIFEST
    unset AI_RIZZ_SOURCE_REPO
    unset AI_RIZZ_TARGET_DIR
    unset AI_RIZZ_RULE_PATH
    unset AI_RIZZ_RULESET_PATH
    unset AI_RIZZ_MODE

    # Create a temporary test directory
    TEST_DIR="$(mktemp -d)"
    
    # Save original HOME
    ORIGINAL_HOME="${HOME}"
    
    # Set up fake HOME for global mode
    TEST_HOME="${TEST_DIR}/test_home"
    mkdir -p "${TEST_HOME}/.cursor/rules"
    mkdir -p "${TEST_HOME}/.cursor/commands"
    HOME="${TEST_HOME}"
    export HOME
    
    # Reset ai-rizz state
    if command -v reset_ai_rizz_state >/dev/null 2>&1; then
        reset_ai_rizz_state
    fi
    
    # Initialize global paths with new HOME
    if command -v init_global_paths >/dev/null 2>&1; then
        init_global_paths
    fi
    
    # Set REPO_DIR to point to the test repo (still needed for source rules)
    REPO_DIR="$TEST_DIR/$TEST_SOURCE_REPO"
    
    # Create repo directory structure (source repository)
    mkdir -p "$REPO_DIR/rules"
    mkdir -p "$REPO_DIR/rulesets/test-ruleset"
    
    # Create rule files in source
    echo "Rule 1 content" > "$REPO_DIR/rules/rule1.mdc"
    echo "Rule 2 content" > "$REPO_DIR/rules/rule2.mdc"
    echo "# Test command" > "$REPO_DIR/rules/cmd1.md"
    
    # Create ruleset
    ln -sf "../../rules/rule1.mdc" "$REPO_DIR/rulesets/test-ruleset/rule1.mdc"
    
    # Initialize source repo as a git repository
    cd "$REPO_DIR" || fail "Failed to change to repo directory"
    git init . >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1
    git add . >/dev/null 2>&1
    git commit -m "Initial commit" --no-gpg-sign >/dev/null 2>&1
    cd "$TEST_DIR" || fail "Failed to change back to test directory"
    
    # Create NON-GIT "app" directory (simulates running outside git repo)
    APP_DIR="${TEST_DIR}/non_git_app"
    mkdir -p "$APP_DIR"
    cd "$APP_DIR" || fail "Failed to change to app directory"
    
    # Explicitly NOT initializing git here - that's the point of this test suite
}

tearDown() {
    # Restore original HOME
    if [ -n "${ORIGINAL_HOME}" ]; then
        HOME="${ORIGINAL_HOME}"
        export HOME
    fi
    
    # Return to original directory before removing test directory
    cd / || fail "Failed to return to root directory"
    
    # Remove test directory and all contents
    rm -rf "$TEST_DIR"
}

# ============================================================================
# GLOBAL-ONLY INIT TESTS
# ============================================================================

test_global_init_works_outside_git_repo() {
    # Test: ai-rizz init --global should work outside a git repo
    # Expected: Successfully initializes global mode
    
    # Verify we're NOT in a git repo
    assertFalse "Should not be in a git repo" "[ -d .git ]"
    
    # This should succeed
    output=$(cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global 2>&1)
    exit_code=$?
    
    assertEquals "Init should succeed" "0" "$exit_code"
    assertTrue "Global manifest should exist" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
}

test_local_init_fails_outside_git_repo() {
    # Test: ai-rizz init --local should gracefully fail outside git repo
    # Expected: Error message about git context
    # Note: Local mode needs git excludes, so it should fail gracefully
    
    # Verify we're NOT in a git repo
    assertFalse "Should not be in a git repo" "[ -d .git ]"
    
    # Try to init local mode - should work but without git excludes
    # (Local mode is designed to work without git, just without exclude management)
    output=$(cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local 2>&1)
    
    # Local mode should still work (just without git exclude management)
    assertTrue "Local manifest should exist" "[ -f '${LOCAL_MANIFEST_FILE}' ]"
}

test_commit_init_fails_outside_git_repo() {
    # Test: ai-rizz init --commit should fail outside git repo
    # Expected: Error message about requiring git
    
    # Verify we're NOT in a git repo
    assertFalse "Should not be in a git repo" "[ -d .git ]"
    
    # This should fail
    output=$(cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit 2>&1)
    exit_code=$?
    
    assertNotEquals "Commit init should fail outside git repo" "0" "$exit_code"
    echo "$output" | grep -qi "git" || fail "Should mention git in error: $output"
}

# ============================================================================
# GLOBAL-ONLY ADD TESTS
# ============================================================================

test_global_add_rule_works_outside_git_repo() {
    # Test: Adding rules in global mode should work outside git repo
    # Expected: Rule successfully added to global mode
    
    assertFalse "Should not be in a git repo" "[ -d .git ]"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "rule1.mdc" --global
    
    assertTrue "Rule should be in global rules dir" \
        "[ -f '${GLOBAL_RULES_DIR}/rule1.mdc' ]"
}

test_global_add_command_works_outside_git_repo() {
    # Test: Adding commands in global mode should work outside git repo
    # Expected: Command successfully added to global mode
    
    assertFalse "Should not be in a git repo" "[ -d .git ]"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "cmd1.md" --global
    
    assertTrue "Command should be in global commands dir" \
        "[ -f '${GLOBAL_COMMANDS_DIR}/cmd1.md' ]"
}

test_global_add_ruleset_works_outside_git_repo() {
    # Test: Adding rulesets in global mode should work outside git repo
    # Expected: Ruleset successfully added to global mode
    
    assertFalse "Should not be in a git repo" "[ -d .git ]"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_ruleset "test-ruleset" --global
    
    assertTrue "Ruleset rule should be in global rules dir" \
        "[ -f '${GLOBAL_RULES_DIR}/rule1.mdc' ]"
}

# ============================================================================
# GLOBAL-ONLY LIST TESTS
# ============================================================================

test_global_list_works_outside_git_repo() {
    # Test: Listing rules in global mode should work outside git repo
    # Expected: Lists global rules with ★ glyph
    
    assertFalse "Should not be in a git repo" "[ -d .git ]"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "rule1.mdc" --global
    
    # Capture list output
    output=$(cmd_list 2>&1)
    
    # Should show the rule with global glyph
    echo "$output" | grep -q "rule1.mdc" || fail "Should list rule1.mdc: $output"
    echo "$output" | grep -q "★" || fail "Should show global glyph: $output"
}

# ============================================================================
# GLOBAL-ONLY DEINIT TESTS
# ============================================================================

test_global_deinit_works_outside_git_repo() {
    # Test: Deinit global mode should work outside git repo
    # Expected: Successfully removes global mode
    
    assertFalse "Should not be in a git repo" "[ -d .git ]"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "rule1.mdc" --global
    
    # Deinit global mode
    output=$(cmd_deinit --global -y 2>&1)
    exit_code=$?
    
    assertEquals "Deinit should succeed" "0" "$exit_code"
    assertFalse "Global manifest should be removed" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
    assertFalse "Global rules dir should be removed" "[ -d '${GLOBAL_RULES_DIR}' ]"
}

# ============================================================================
# SMART MODE SELECTION OUTSIDE GIT REPO
# ============================================================================

test_smart_mode_selects_global_when_only_global_initialized() {
    # Test: When only global mode is initialized outside git, select_mode should auto-select it
    # Expected: Automatically selects global mode without requiring --global flag
    
    assertFalse "Should not be in a git repo" "[ -d .git ]"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    # Now add rule without specifying mode - should auto-select global
    output=$(cmd_add_rule "rule1.mdc" 2>&1)
    
    # Should succeed and add to global
    assertTrue "Rule should be in global rules dir" \
        "[ -f '${GLOBAL_RULES_DIR}/rule1.mdc' ]"
}

# ============================================================================
# HELP DOCUMENTATION TESTS
# ============================================================================

test_help_mentions_global_option() {
    # Test: Help output should mention --global option
    # Expected: Help includes --global in init, add, and deinit sections
    
    output=$(cmd_help 2>&1)
    
    echo "$output" | grep -qi "global" || \
        fail "Help should mention global option: $output"
    
    echo "$output" | grep -qi "\-g" || echo "$output" | grep -qi "\-\-global" || \
        fail "Help should mention -g or --global flag: $output"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
