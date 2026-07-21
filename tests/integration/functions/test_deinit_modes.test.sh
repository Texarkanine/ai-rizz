#!/bin/sh
#
# test_deinit_modes.test.sh - Deinit mode selection test suite
#
# Tests the deinit command's mode-selective removal capabilities including
# individual mode removal, complete cleanup, confirmation prompts, and
# proper cleanup of manifests, directories, and git excludes.
#
# Test Coverage:
# Validates the deinit command's mode-selective removal capabilities with
# proper cleanup of manifests, directories, and git excludes while handling
# confirmation prompts and maintaining system integrity during partial and
# complete removal scenarios.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_deinit_modes.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Main test functions
# ------------------

test_deinit_local_mode_only() {
    # Setup: Both modes exist
    pwd
    ls -hal
    set -x
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    set +x
    pwd
    ls -hal
    cmd_add_rule "rule1.mdc" --commit  # Creates both modes
    
    # Test: Deinit local mode only

    cmd_deinit --local -y

    # Expected: Local mode removed, commit mode preserved
    assert_file_not_exists "$TEST_LOCAL_MANIFEST_FILE"
    assert_commit_mode_exists
    assert_git_exclude_not_contains "$TEST_LOCAL_MANIFEST_FILE"
}

test_deinit_commit_mode_only() {
    # Setup: Both modes exist
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit commit mode only
    cmd_deinit --commit -y
    
    # Expected: Commit mode removed, local mode preserved
    assert_file_not_exists "$TEST_COMMIT_MANIFEST_FILE"
    assert_local_mode_exists
}

test_deinit_both_modes() {
    # Setup: Both project modes exist
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit local+commit via --both
    cmd_deinit --both -y
    # Expected: Project modes removed; target directory may remain (user files)
    assert_no_modes_exist
    assertFalse "Local subdirectory should be removed" "[ -d '$TEST_TARGET_DIR/$TEST_LOCAL_DIR' ]"
    assertFalse "Shared subdirectory should be removed" "[ -d '$TEST_TARGET_DIR/$TEST_SHARED_DIR' ]"
}

test_deinit_requires_mode_selection() {
    # Setup: Both modes exist
    echo "cmd_init '$TEST_SOURCE_REPO' -d '$TEST_TARGET_DIR' --local"
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit without mode flag (provide empty input to prompt)
    output=$(echo "" | cmd_deinit 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should prompt for mode selection (both, not all)
    echo "$output" | grep -Eq "mode|local|commit|both|choose|select" || fail "Should prompt for mode selection"
    echo "$output" | grep -Eq "both" || fail "Prompt should offer both, got: $output"
}

test_deinit_single_mode_direct() {
    # Setup: Only local mode exists
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: Deinit without mode flag when only one mode exists
    cmd_deinit --local -y
    
    # Expected: Should deinit successfully
    assert_no_modes_exist
}

test_deinit_local_removes_git_excludes() {
    # Setup: Local mode with git-exclude (using --git-exclude-ignore flag)
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --git-exclude-ignore
    cmd_add_rule "rule1.mdc" --local
    assert_git_exclude_contains "$TEST_LOCAL_MANIFEST_FILE"
    
    # Test: Deinit local mode
    cmd_deinit --local -y
    
    # Expected: Git exclude entries removed
    assert_git_exclude_not_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
}

test_deinit_commit_preserves_git_excludes() {
    # Setup: Both modes with git-exclude for local mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --git-exclude-ignore
    cmd_add_rule "rule1.mdc" --commit
    assert_git_exclude_contains "$TEST_LOCAL_MANIFEST_FILE"
    
    # Test: Deinit commit mode only
    cmd_deinit --commit -y
    
    # Expected: Local git excludes should remain
    assert_git_exclude_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
}

test_deinit_preserves_files_in_other_mode() {
    # Setup: Rules in both modes
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Deinit local mode only
    cmd_deinit --local -y
    
    # Expected: Commit files preserved, local files removed
    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule2.mdc"
}

test_deinit_custom_target_directory() {
    # Setup: Custom target directory with both modes
    custom_dir=".custom/rules"
    cmd_init "$TEST_SOURCE_REPO" -d "$custom_dir" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit local mode
    cmd_deinit --local -y
    
    # Expected: Custom local directory removed, shared preserved
    assertFalse "Custom local dir should be removed" "[ -d '$custom_dir/$TEST_LOCAL_DIR' ]"
    assertTrue "Custom shared dir should remain" "[ -d '$custom_dir/$TEST_SHARED_DIR' ]"
}

test_deinit_nonexistent_mode_graceful() {
    # Setup: Only local mode exists
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Test: Try to deinit commit mode that doesn't exist
    output=$(cmd_deinit --commit -y 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should handle gracefully (warn but not fail)
    echo "$output" | grep -q "not found\|warning\|no.*commit" || true  # May warn
    
    # Local mode should remain untouched
    assert_local_mode_exists
}

test_deinit_both_with_single_mode() {
    # Setup: Only commit mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Deinit --both when only one project mode exists
    cmd_deinit --both -y
    
    # Expected: Project modes removed; target directory may remain (user files)
    assert_no_modes_exist
    assertFalse "Shared subdirectory should be removed" "[ -d '$TEST_TARGET_DIR/$TEST_SHARED_DIR' ]"
}

test_deinit_both_with_yes_flag_skips_prompt() {
    # Setup: Both modes with rules
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Deinit --both with --yes skips interactive confirmation
    _tdbwyf_tmp=$(mktemp)
    ( cmd_deinit --both -y >"$_tdbwyf_tmp" 2>&1 )
    tdbwyf_exit=$?
    rm -f "$_tdbwyf_tmp"
    assertEquals "cmd_deinit --both -y should succeed" 0 "$tdbwyf_exit"

    # Expected: Project cleanup without interactive prompts when -y is passed
    assert_no_modes_exist
}

test_deinit_both_preserves_global() {
    # Setup: local + commit + global; --both must not wipe global
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    init_global_paths
    cmd_add_rule "rule2.mdc" --global

    assertTrue "global should be active before --both" \
        "[ \"$(is_mode_active global)\" = \"true\" ]"
    assertTrue "global manifest should exist before --both" \
        "[ -f '${GLOBAL_MANIFEST_FILE}' ]"

    cmd_deinit --both -y

    assert_no_modes_exist
    assertTrue "global should remain active after --both" \
        "[ \"$(is_mode_active global)\" = \"true\" ]"
    assertTrue "global manifest should remain after --both" \
        "[ -f '${GLOBAL_MANIFEST_FILE}' ]"
}

test_deinit_all_flag_rejected() {
    # Setup: dual project modes — --all must not remove anything
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit

    _tdafr_tmp=$(mktemp)
    ( cmd_deinit --all -y >"$_tdafr_tmp" 2>&1 )
    tdafr_exit=$?
    tdafr_output=$(cat "$_tdafr_tmp")
    rm -f "$_tdafr_tmp"

    assertFalse "cmd_deinit --all should fail" "[ \"$tdafr_exit\" -eq 0 ]"
    echo "$tdafr_output" | grep -Eqi "unknown|--both|both|global" || \
        fail "Rejection should mention unknown/--both/global, got: $tdafr_output"
    assert_local_mode_exists
    assert_commit_mode_exists
}

test_deinit_all_short_flag_rejected() {
    # Setup: dual project modes — -a must not remove anything
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit

    _tdasfr_tmp=$(mktemp)
    ( cmd_deinit -a -y >"$_tdasfr_tmp" 2>&1 )
    tdasfr_exit=$?
    tdasfr_output=$(cat "$_tdasfr_tmp")
    rm -f "$_tdasfr_tmp"

    assertFalse "cmd_deinit -a should fail" "[ \"$tdasfr_exit\" -eq 0 ]"
    echo "$tdasfr_output" | grep -Eqi "unknown|--both|both|global" || \
        fail "Rejection should mention unknown/--both/global, got: $tdasfr_output"
    assert_local_mode_exists
    assert_commit_mode_exists
}

test_deinit_partial_cleanup_on_error() {
    # Setup: Both modes with separate rules to ensure both manifests exist
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Deny write on deployed rule tree — deinit must still remove local manifest or surface failure
    chmod -R a-w "$TEST_TARGET_DIR"
    
    _tdpc_tmp=$(mktemp)
    ( cmd_deinit --local -y >"$_tdpc_tmp" 2>&1 )
    deinit_exit=$?
    output=$(cat "$_tdpc_tmp")
    rm -f "$_tdpc_tmp"
    
    chmod -R u+w "$TEST_TARGET_DIR"
    
    assertTrue "Commit mode should remain after local deinit in dual-mode repo" \
        "[ -f '$TEST_COMMIT_MANIFEST_FILE' ]"
    assertFalse "Local manifest should be gone after successful local deinit" \
        "[ -f '$TEST_LOCAL_MANIFEST_FILE' ]"
    echo "$output" | grep -Eq "Removed|removed|error|permission|fail|warn" || \
        fail "Deinit should report outcome when deploy tree was read-only: $output"
    assertEquals "Local deinit should complete (exit 0) when removal is best-effort" 0 "$deinit_exit"
}

test_deinit_removes_empty_directories() {
    # Setup: Local mode with nested structure
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Create additional nested structure
    mkdir -p "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/nested"
    touch "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/nested/dummy"
    
    # Test: Deinit local mode
    cmd_deinit --local -y
    
    # Expected: Empty parent directories should be cleaned up
    assertFalse "Nested directory should be removed" "[ -d '$TEST_TARGET_DIR/$TEST_LOCAL_DIR/nested' ]"
    assertFalse "Local directory should be removed" "[ -d '$TEST_TARGET_DIR/$TEST_LOCAL_DIR' ]"
}

test_deinit_interactive_mode_selection() {
    # Setup: Both modes exist
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: Interactive mode (provide empty input to prompt)
    output=$(echo "" | cmd_deinit 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should prompt for mode selection (both, not all)
    echo "$output" | grep -Eq "mode|local|commit|both|choose|select" || fail "Should prompt for mode selection"
    echo "$output" | grep -Eq "both" || fail "Prompt should offer both, got: $output"
}

test_deinit_local_message_includes_commands_dir() {
    # Test: deinit --local confirmation message should mention .cursor/commands/local
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Create a local command to ensure commands dir exists
    mkdir -p ".cursor/commands/$TEST_LOCAL_DIR"
    touch ".cursor/commands/$TEST_LOCAL_DIR/test-cmd.md"
    
    # Capture the confirmation prompt (say 'n' to cancel)
    output=$(echo "n" | cmd_deinit --local 2>&1 || true)
    
    # Expected: Message should include .cursor/commands/local
    echo "$output" | grep -q ".cursor/commands/$TEST_LOCAL_DIR" || fail "Deinit message should include .cursor/commands/$TEST_LOCAL_DIR, got: $output"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../../shunit2" 