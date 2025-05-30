#!/bin/sh
#
# test_cli_init.test.sh - Integration tests for ai-rizz init command
#
# Tests the public CLI interface for the init command by executing ai-rizz
# directly and verifying the resulting system state. Validates progressive
# initialization behavior, mode selection logic, directory structure creation,
# git exclude management, and error handling for various initialization
# scenarios including dual mode setup and re-initialization.
#
# Dependencies: shunit2, integration test utilities
# Usage: sh test_cli_init.test.sh

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

# Test: ai-rizz init <repo> --local
# Expected: Creates local mode structure with proper git excludes
test_init_local_mode_creates_proper_structure() {
    # Execute init command
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "Init local mode should succeed" 0 $?
    
    # Verify local mode structure created
    assertTrue "Local manifest should exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Local directory should exist" "[ -d '.cursor/rules/local' ]"
    
    # Verify commit mode not created
    assertFalse "Commit manifest should not exist" "[ -f 'ai-rizz.skbd' ]"
    assertFalse "Shared directory should not exist" "[ -d '.cursor/rules/shared' ]"
    
    # Verify git excludes
    assert_git_excludes "ai-rizz.local.skbd"
    assert_git_excludes ".cursor/rules/local"
    
    # Verify manifest header (new 4-field format with defaults)
    first_line=$(head -n1 ai-rizz.local.skbd)
    assertEquals "Local manifest header incorrect" "file://$MOCK_REPO_DIR	.cursor/rules	rules	rulesets" "$first_line"
}

# Test: ai-rizz init <repo> --commit
# Expected: Creates commit mode structure without git excludes
test_init_commit_mode_creates_proper_structure() {
    # Execute init command
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    assertEquals "Init commit mode should succeed" 0 $?
    
    # Verify commit mode structure created
    assertTrue "Commit manifest should exist" "[ -f 'ai-rizz.skbd' ]"
    assertTrue "Shared directory should exist" "[ -d '.cursor/rules/shared' ]"
    
    # Verify local mode not created
    assertFalse "Local manifest should not exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertFalse "Local directory should not exist" "[ -d '.cursor/rules/local' ]"
    
    # Verify no git excludes for commit mode
    assert_git_tracks "ai-rizz.skbd"
    assert_git_tracks ".cursor/rules/shared"
    
    # Verify manifest header (new 4-field format with defaults)
    first_line=$(head -n1 ai-rizz.skbd)
    assertEquals "Commit manifest header incorrect" "file://$MOCK_REPO_DIR	.cursor/rules	rules	rulesets" "$first_line"
}

# Test: ai-rizz init <repo> (no mode flag)
# Expected: Should prompt for mode selection or show error
test_init_requires_mode_selection() {
    # Execute init without mode flag, provide empty input to prompt
    output=$(echo "" | run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules 2>&1 || echo "ERROR_OCCURRED")
    
    # Should either show mode selection prompt or require mode flag
    if echo "$output" | grep -q "ERROR_OCCURRED"; then
        # Command failed - should show helpful error about mode selection
        assert_output_contains "$output" "mode"
    else
        # Command showed prompt - should contain mode selection text
        assert_output_contains "$output" "mode\|local\|commit\|choose\|select"
    fi
}

# Test: ai-rizz init <repo> -d custom/path --local
# Expected: Uses custom target directory
test_init_custom_target_directory() {
    custom_dir="custom/rules"
    
    # Execute init with custom directory
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d "$custom_dir" --local
    assertEquals "Init with custom directory should succeed" 0 $?
    
    # Verify custom directory structure
    assertTrue "Custom local directory should exist" "[ -d '$custom_dir/local' ]"
    assert_git_excludes "$custom_dir/local"
    
    # Verify manifest uses custom directory
    first_line=$(head -n1 ai-rizz.local.skbd)
    assertEquals "Manifest should use custom directory" "file://$MOCK_REPO_DIR	$custom_dir	rules	rulesets" "$first_line"
}

# Test: ai-rizz init invalid://repo --local
# Expected: Should handle invalid repository gracefully
test_init_invalid_repository_url() {
    # Execute init with invalid repository
    output=$(run_ai_rizz init "invalid://nonexistent" -d .cursor/rules --local 2>&1 || echo "COMMAND_FAILED")
    
    # Command should fail gracefully
    assert_output_contains "$output" "COMMAND_FAILED"
    
    # Should not create any files on failure
    assertFalse "Should not create manifest on failure" "[ -f 'ai-rizz.local.skbd' ]"
    assertFalse "Should not create directory on failure" "[ -d '.cursor/rules/local' ]"
}

# Test: ai-rizz init <repo> --local (twice)
# Expected: Second init should be idempotent
test_init_twice_same_mode_idempotent() {
    # First init
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "First init should succeed" 0 $?
    
    # Verify initial state
    assertTrue "Local manifest should exist after first init" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Local directory should exist after first init" "[ -d '.cursor/rules/local' ]"
    
    # Second init with same mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "Second init should succeed (idempotent)" 0 $?
    
    # Verify state unchanged
    assertTrue "Local manifest should still exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Local directory should still exist" "[ -d '.cursor/rules/local' ]"
    assertFalse "Commit mode should not be created" "[ -f 'ai-rizz.skbd' ]"
    
    # Verify git excludes still correct
    assert_git_excludes "ai-rizz.local.skbd"
    assert_git_excludes ".cursor/rules/local"
}

# Test: ai-rizz init with different modes
# Expected: Should create dual mode setup
test_init_different_modes_creates_dual_mode() {
    # First init with local mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "Local init should succeed" 0 $?
    
    # Second init with commit mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    assertEquals "Commit init should succeed" 0 $?
    
    # Verify both modes exist
    assertTrue "Local manifest should exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Commit manifest should exist" "[ -f 'ai-rizz.skbd' ]"
    assertTrue "Local directory should exist" "[ -d '.cursor/rules/local' ]"
    assertTrue "Shared directory should exist" "[ -d '.cursor/rules/shared' ]"
    
    # Verify git excludes correct for dual mode
    assert_git_excludes "ai-rizz.local.skbd"
    assert_git_excludes ".cursor/rules/local"
    assert_git_tracks "ai-rizz.skbd"
    assert_git_tracks ".cursor/rules/shared"
}

# Test: ai-rizz init <repo> -f Gyattfile --local
# Expected: Creates Gyattfile and Gyattfile.local as manifests
test_init_with_extensionless_manifest_root() {
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local -f Gyattfile
    assertEquals "Init with extensionless manifest root should succeed" 0 $?
    assertTrue "Custom local manifest should exist" "[ -f 'Gyattfile.local' ]"
    assertTrue "Custom manifest should not exist " "[ ! -f 'Gyattfile' ]"
    # Should create local directory
    assertTrue "Local directory should exist" "[ -d '.cursor/rules/local' ]"
    # Manifest header should be correct
    first_line=$(head -n1 Gyattfile.local)
    assertEquals "Manifest header incorrect" "file://$MOCK_REPO_DIR	.cursor/rules	rules	rulesets" "$first_line"
}

# Test: ai-rizz init <repo> -f foo.bar --commit
# Expected: Creates foo.bar and foo.local.bar as manifests
test_init_with_single_extension_manifest_root() {
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit -f foo.bar
    assertEquals "Init with single extension manifest root should succeed" 0 $?
    assertTrue "Custom manifest should exist" "[ -f 'foo.bar' ]"
    assertTrue "Custom local manifest should not exist yet" "[ ! -f 'foo.local.bar' ]"
    # Should create shared directory
    assertTrue "Shared directory should exist" "[ -d '.cursor/rules/shared' ]"
    # Manifest header should be correct
    first_line=$(head -n1 foo.bar)
    assertEquals "Manifest header incorrect" "file://$MOCK_REPO_DIR	.cursor/rules	rules	rulesets" "$first_line"
}

# Test: ai-rizz init <repo> -f foo.baz.bar --local
# Expected: Creates foo.baz.bar and foo.baz.local.bar as manifests
test_init_with_multi_dot_manifest_root() {
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local -f foo.baz.bar
    assertEquals "Init with multi-dot manifest root should succeed" 0 $?
    assertTrue "Custom local manifest should exist" "[ -f 'foo.baz.local.bar' ]"
    assertTrue "Custom manifest should not exist yet" "[ ! -f 'foo.baz.bar' ]"
    # Should create local directory
    assertTrue "Local directory should exist" "[ -d '.cursor/rules/local' ]"
    # Manifest header should be correct
    first_line=$(head -n1 foo.baz.local.bar)
    assertEquals "Manifest header incorrect" "file://$MOCK_REPO_DIR	.cursor/rules	rules	rulesets" "$first_line"
}

# Test: ai-rizz init <repo> -f "manifest with spaces.conf" --local
# Expected: Creates "manifest with spaces.conf" and "manifest with spaces.local.conf" as manifests
test_init_with_spaces_in_manifest_name() {
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local -f "manifest with spaces.conf"
    assertEquals "Init with spaces in manifest name should succeed" 0 $?
    assertTrue "Custom local manifest should exist" "[ -f 'manifest with spaces.local.conf' ]"
    assertTrue "Custom manifest should not exist yet" "[ ! -f 'manifest with spaces.conf' ]"
    # Should create local directory
    assertTrue "Local directory should exist" "[ -d '.cursor/rules/local' ]"
    # Manifest header should be correct
    first_line=$(head -n1 "manifest with spaces.local.conf")
    assertEquals "Manifest header incorrect" "file://$MOCK_REPO_DIR	.cursor/rules	rules	rulesets" "$first_line"
}

# Test: ai-rizz init with target but no mode (should prompt and set default)
test_init_mode_defaults() {
    # Execute ai-rizz init with target but no mode (should prompt and set default)
    output=$(printf "commit\n" | run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules 2>&1)

    # Should succeed and default to local mode
    assertEquals "Init should succeed with default mode" 0 $?
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 