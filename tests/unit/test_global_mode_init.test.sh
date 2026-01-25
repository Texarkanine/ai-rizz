#!/bin/sh
#
# test_global_mode_init.test.sh - Global mode initialization test suite
#
# Tests all aspects of ai-rizz global mode initialization including:
# - Global manifest creation and structure
# - Global directory setup (~/.cursor/rules/ai-rizz/, ~/.cursor/commands/ai-rizz/)
# - Interaction with repository modes (local/commit)
# - Idempotent re-initialization behavior
#
# Test Environment:
# Global mode operates at the user level ($HOME), so tests use TEST_HOME
# to isolate global mode operations from the real home directory.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_global_mode_init.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# TEST SETUP - Global mode isolation using TEST_HOME
# ============================================================================

# Override HOME for global mode testing
setup_global_test_environment() {
    # Create isolated home directory for testing
    TEST_HOME="${TEST_DIR}/test_home"
    mkdir -p "${TEST_HOME}/.cursor/rules"
    mkdir -p "${TEST_HOME}/.cursor/commands"
    
    # Save original HOME and override
    ORIGINAL_HOME="${HOME}"
    HOME="${TEST_HOME}"
    export HOME
    
    # Re-initialize global paths with new HOME
    init_global_paths
}

teardown_global_test_environment() {
    # Restore original HOME
    if [ -n "${ORIGINAL_HOME}" ]; then
        HOME="${ORIGINAL_HOME}"
        export HOME
    fi
}

# Override setUp to include global test environment setup
oneTimeSetUp() {
    :
}

oneTimeTearDown() {
    :
}

# ============================================================================
# GLOBAL MODE CONSTANTS TESTS
# ============================================================================

test_global_constants_defined() {
    # Test: Global mode constants should be defined
    # Expected: GLOBAL_MANIFEST_FILE, GLOBAL_RULES_DIR, GLOBAL_COMMANDS_DIR exist
    
    setup_global_test_environment
    
    assertNotNull "GLOBAL_MANIFEST_FILE should be defined" "${GLOBAL_MANIFEST_FILE}"
    assertEquals "GLOBAL_MANIFEST_FILE should be ~/ai-rizz.skbd" "${HOME}/ai-rizz.skbd" "${GLOBAL_MANIFEST_FILE}"
    
    assertNotNull "GLOBAL_RULES_DIR should be defined" "${GLOBAL_RULES_DIR}"
    assertEquals "GLOBAL_RULES_DIR should be ~/.cursor/rules/ai-rizz" "${HOME}/.cursor/rules/ai-rizz" "${GLOBAL_RULES_DIR}"
    
    assertNotNull "GLOBAL_COMMANDS_DIR should be defined" "${GLOBAL_COMMANDS_DIR}"
    assertEquals "GLOBAL_COMMANDS_DIR should be ~/.cursor/commands/ai-rizz" "${HOME}/.cursor/commands/ai-rizz" "${GLOBAL_COMMANDS_DIR}"
    
    teardown_global_test_environment
}

test_global_glyph_defined() {
    # Test: Global mode glyph should be defined
    # Expected: GLOBAL_GLYPH = "★"
    
    assertNotNull "GLOBAL_GLYPH should be defined" "${GLOBAL_GLYPH}"
    assertEquals "GLOBAL_GLYPH should be ★" "★" "${GLOBAL_GLYPH}"
}

# ============================================================================
# GLOBAL MODE INITIALIZATION TESTS
# ============================================================================

test_init_global_mode_creates_manifest() {
    # Test: ai-rizz init $REPO --global
    # Expected: Creates global manifest at ~/ai-rizz.skbd
    
    setup_global_test_environment
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    assertTrue "Global manifest should exist" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
    
    teardown_global_test_environment
}

test_init_global_mode_creates_directories() {
    # Test: ai-rizz init $REPO --global
    # Expected: Creates global rules and commands directories
    
    setup_global_test_environment
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    assertTrue "Global rules directory should exist" "[ -d '${GLOBAL_RULES_DIR}' ]"
    assertTrue "Global commands directory should exist" "[ -d '${GLOBAL_COMMANDS_DIR}' ]"
    
    teardown_global_test_environment
}

test_init_global_mode_manifest_header() {
    # Test: Global manifest should have correct header format
    # Expected: Same format as local/commit manifests
    
    setup_global_test_environment
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    first_line=$(head -n1 "${GLOBAL_MANIFEST_FILE}")
    echo "$first_line" | grep -q "${TEST_SOURCE_REPO}" || fail "Global manifest should contain source repo"
    
    teardown_global_test_environment
}

test_init_global_mode_idempotent() {
    # Test: Running init --global twice should be idempotent
    # Expected: No error, same result
    
    setup_global_test_environment
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    assertTrue "First init should succeed" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
    
    # Init again with same parameters
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    assertTrue "Second init should succeed" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
    
    teardown_global_test_environment
}

test_init_global_outside_git_repo() {
    # Test: ai-rizz init --global should work outside a git repository
    # Expected: Global mode initializes successfully
    
    setup_global_test_environment
    
    # Create and move to non-git directory
    non_git_dir="${TEST_DIR}/non_git_dir"
    mkdir -p "${non_git_dir}"
    cd "${non_git_dir}" || fail "Failed to change to non-git directory"
    
    # This should NOT fail (unlike local/commit modes which require git)
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    assertTrue "Global manifest should exist" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
    
    # Return to test directory
    cd "${TEST_DIR}" || fail "Failed to return to test directory"
    
    teardown_global_test_environment
}

test_init_global_uses_existing_repo_source() {
    # Test: ai-rizz init <repo> --global should work after commit mode exists
    # Expected: Both modes coexist and use the same source repo
    
    setup_global_test_environment
    
    # First, initialize commit mode in a repo
    cd "${APP_DIR}" || fail "Failed to change to app directory"
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    
    # Now init global mode - since commit mode exists, it should use same source
    # Note: We still need to provide the source repo because the unified variable
    # check happens but the test source repo path would be used
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    assertTrue "Global manifest should exist" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
    
    # Global manifest should reference same source repo
    first_line=$(head -n1 "${GLOBAL_MANIFEST_FILE}")
    echo "$first_line" | grep -q "${TEST_SOURCE_REPO}" || fail "Global manifest should use same source repo"
    
    teardown_global_test_environment
}

# ============================================================================
# GLOBAL MODE COEXISTENCE TESTS
# ============================================================================

test_init_global_with_existing_local() {
    # Test: Initialize global mode when local mode already exists
    # Expected: Both modes coexist independently
    
    setup_global_test_environment
    cd "${APP_DIR}" || fail "Failed to change to app directory"
    
    # Initialize local mode first
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    assertTrue "Local mode should exist" "[ -f '${LOCAL_MANIFEST_FILE}' ]"
    
    # Initialize global mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    # Both should exist
    assertTrue "Local mode should still exist" "[ -f '${LOCAL_MANIFEST_FILE}' ]"
    assertTrue "Global manifest should exist" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
    
    teardown_global_test_environment
}

test_init_global_with_existing_commit() {
    # Test: Initialize global mode when commit mode already exists
    # Expected: Both modes coexist independently
    
    setup_global_test_environment
    cd "${APP_DIR}" || fail "Failed to change to app directory"
    
    # Initialize commit mode first
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    assertTrue "Commit mode should exist" "[ -f '${COMMIT_MANIFEST_FILE}' ]"
    
    # Initialize global mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    # Both should exist
    assertTrue "Commit mode should still exist" "[ -f '${COMMIT_MANIFEST_FILE}' ]"
    assertTrue "Global manifest should exist" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
    
    teardown_global_test_environment
}

test_init_all_three_modes() {
    # Test: All three modes can coexist
    # Expected: local, commit, and global all active
    
    setup_global_test_environment
    cd "${APP_DIR}" || fail "Failed to change to app directory"
    
    # Initialize all three modes
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    # All three should exist
    assertTrue "Local mode should exist" "[ -f '${LOCAL_MANIFEST_FILE}' ]"
    assertTrue "Commit mode should exist" "[ -f '${COMMIT_MANIFEST_FILE}' ]"
    assertTrue "Global manifest should exist" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
    
    # Mode detection should work for all three
    assertTrue "Should detect local mode" "[ \"\$(is_mode_active local)\" = \"true\" ]"
    assertTrue "Should detect commit mode" "[ \"\$(is_mode_active commit)\" = \"true\" ]"
    assertTrue "Should detect global mode" "[ \"\$(is_mode_active global)\" = \"true\" ]"
    
    teardown_global_test_environment
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
