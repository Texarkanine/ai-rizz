#!/bin/sh
#
# test_global_mode_detection.test.sh - Global mode detection test suite
#
# Tests mode detection with three modes including:
# - is_mode_active() with global mode
# - Smart mode selection with three modes
# - Mode priority rules
# - get_any_manifest_metadata() with global manifest
#
# Test Environment:
# Uses TEST_HOME to isolate global mode operations from the real home directory.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_global_mode_detection.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# TEST SETUP - Global mode isolation using TEST_HOME
# ============================================================================

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

# ============================================================================
# is_mode_active() TESTS
# ============================================================================

test_is_mode_active_global_no_manifest() {
    # Test: is_mode_active global when no global manifest exists
    # Expected: Returns "false"
    
    setup_global_test_environment
    
    # Ensure no global manifest
    rm -f "${HOME}/ai-rizz.skbd"
    
    result=$(is_mode_active global)
    assertEquals "Should return false when no global manifest" "false" "${result}"
    
    teardown_global_test_environment
}

test_is_mode_active_global_with_manifest() {
    # Test: is_mode_active global when global manifest exists
    # Expected: Returns "true"
    
    setup_global_test_environment
    
    # Initialize global mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    result=$(is_mode_active global)
    assertEquals "Should return true when global manifest exists" "true" "${result}"
    
    teardown_global_test_environment
}

test_is_mode_active_all_modes() {
    # Test: is_mode_active returns correct results for all three modes
    # Expected: Each mode detected independently
    
    setup_global_test_environment
    cd "${APP_DIR}" || fail "Failed to change to app directory"
    
    # Start with no modes
    assertFalse "Should not detect local mode initially" "[ \"\$(is_mode_active local)\" = \"true\" ]"
    assertFalse "Should not detect commit mode initially" "[ \"\$(is_mode_active commit)\" = \"true\" ]"
    assertFalse "Should not detect global mode initially" "[ \"\$(is_mode_active global)\" = \"true\" ]"
    
    # Add local mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    assertTrue "Should detect local mode" "[ \"\$(is_mode_active local)\" = \"true\" ]"
    assertFalse "Should not detect commit mode" "[ \"\$(is_mode_active commit)\" = \"true\" ]"
    assertFalse "Should not detect global mode" "[ \"\$(is_mode_active global)\" = \"true\" ]"
    
    # Add commit mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    assertTrue "Should detect local mode" "[ \"\$(is_mode_active local)\" = \"true\" ]"
    assertTrue "Should detect commit mode" "[ \"\$(is_mode_active commit)\" = \"true\" ]"
    assertFalse "Should not detect global mode" "[ \"\$(is_mode_active global)\" = \"true\" ]"
    
    # Add global mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    assertTrue "Should detect local mode" "[ \"\$(is_mode_active local)\" = \"true\" ]"
    assertTrue "Should detect commit mode" "[ \"\$(is_mode_active commit)\" = \"true\" ]"
    assertTrue "Should detect global mode" "[ \"\$(is_mode_active global)\" = \"true\" ]"
    
    teardown_global_test_environment
}

# ============================================================================
# SMART MODE SELECTION TESTS (select_mode())
# ============================================================================

test_select_mode_only_global_active() {
    # Test: select_mode() with only global mode active
    # Expected: Returns "global" automatically
    
    setup_global_test_environment
    
    # Create non-git directory (so local/commit can't be active)
    non_git_dir="${TEST_DIR}/non_git_dir"
    mkdir -p "${non_git_dir}"
    cd "${non_git_dir}" || fail "Failed to change to non-git directory"
    
    # Initialize only global mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    # Cache must be refreshed
    cache_manifest_metadata
    
    result=$(select_mode "")
    assertEquals "Should auto-select global when only global is active" "global" "${result}"
    
    cd "${TEST_DIR}" || fail "Failed to return to test directory"
    teardown_global_test_environment
}

test_select_mode_explicit_global_flag() {
    # Test: select_mode() with explicit "global" argument
    # Expected: Returns "global" regardless of other modes
    
    setup_global_test_environment
    cd "${APP_DIR}" || fail "Failed to change to app directory"
    
    # Initialize all three modes
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    result=$(select_mode "global")
    assertEquals "Should return global when explicitly specified" "global" "${result}"
    
    teardown_global_test_environment
}

test_select_mode_requires_flag_with_three_modes() {
    # Test: select_mode() with all three modes active and no flag
    # Expected: Shows error asking for mode specification
    
    setup_global_test_environment
    cd "${APP_DIR}" || fail "Failed to change to app directory"
    
    # Initialize all three modes
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    # select_mode without argument should fail when multiple modes active
    # We need to capture the error - the function calls error() which exits
    output=$(select_mode "" 2>&1 || echo "ERROR_OCCURRED")
    
    echo "$output" | grep -q "mode\|--local\|--commit\|--global\|specify" || fail "Should show mode selection error"
    
    teardown_global_test_environment
}

test_select_mode_two_modes_local_global() {
    # Test: select_mode() with local and global active (no flag)
    # Expected: Shows error asking for mode specification
    
    setup_global_test_environment
    cd "${APP_DIR}" || fail "Failed to change to app directory"
    
    # Initialize local and global modes
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    output=$(select_mode "" 2>&1 || echo "ERROR_OCCURRED")
    
    echo "$output" | grep -q "mode\|--local\|--global\|specify" || fail "Should show mode selection error"
    
    teardown_global_test_environment
}

# ============================================================================
# MODE PRIORITY TESTS
# ============================================================================

test_mode_priority_commit_over_global() {
    # Test: Both commit and global modes can coexist
    # Expected: Both modes are active simultaneously
    # Note: Priority testing for rules will be in Phase 3 (list display tests)
    
    setup_global_test_environment
    cd "${APP_DIR}" || fail "Failed to change to app directory"
    
    # Initialize both modes
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    # Both modes should be active
    assertTrue "Commit mode should be active" "[ \"\$(is_mode_active commit)\" = \"true\" ]"
    assertTrue "Global mode should be active" "[ \"\$(is_mode_active global)\" = \"true\" ]"
    
    # Verify manifest files exist
    assertTrue "Commit manifest should exist" "[ -f '${COMMIT_MANIFEST_FILE}' ]"
    assertTrue "Global manifest should exist" "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
    
    teardown_global_test_environment
}

# ============================================================================
# GLOBAL MANIFEST METADATA TESTS
# ============================================================================

test_get_any_manifest_metadata_includes_global() {
    # Test: get_any_manifest_metadata() should include global manifest
    # Expected: Returns metadata from global manifest when it's the only one
    
    setup_global_test_environment
    
    # Create non-git directory
    non_git_dir="${TEST_DIR}/non_git_dir"
    mkdir -p "${non_git_dir}"
    cd "${non_git_dir}" || fail "Failed to change to non-git directory"
    
    # Initialize only global mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    # get_any_manifest_metadata should return global manifest metadata
    metadata=$(get_any_manifest_metadata)
    
    echo "$metadata" | grep -q "${TEST_SOURCE_REPO}" || fail "Should return metadata from global manifest"
    
    cd "${TEST_DIR}" || fail "Failed to return to test directory"
    teardown_global_test_environment
}

test_cache_manifest_metadata_includes_global() {
    # Test: cache_manifest_metadata() should populate unified metadata globals from global manifest
    # Expected: SOURCE_REPO is set from global manifest when it's the only one
    
    setup_global_test_environment
    
    # Create non-git directory
    non_git_dir="${TEST_DIR}/non_git_dir"
    mkdir -p "${non_git_dir}"
    cd "${non_git_dir}" || fail "Failed to change to non-git directory"
    
    # Initialize only global mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    # Refresh cache
    cache_manifest_metadata
    
    assertNotNull "SOURCE_REPO should be set from global manifest" "${SOURCE_REPO}"
    echo "${SOURCE_REPO}" | grep -q "${TEST_SOURCE_REPO}" || fail "SOURCE_REPO should match source repo from global manifest"
    
    cd "${TEST_DIR}" || fail "Failed to return to test directory"
    teardown_global_test_environment
}

# ============================================================================
# GLOBAL MODE ENVIRONMENT VARIABLE TESTS
# ============================================================================

test_ai_rizz_mode_env_global() {
    # Test: AI_RIZZ_MODE=global should work as fallback
    # Expected: select_mode() uses environment variable
    
    setup_global_test_environment
    cd "${APP_DIR}" || fail "Failed to change to app directory"
    
    # Initialize all three modes
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    # Set environment variable
    AI_RIZZ_MODE="global"
    export AI_RIZZ_MODE
    
    result=$(select_mode "")
    assertEquals "Should use AI_RIZZ_MODE=global" "global" "${result}"
    
    # Clean up
    unset AI_RIZZ_MODE
    
    teardown_global_test_environment
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
